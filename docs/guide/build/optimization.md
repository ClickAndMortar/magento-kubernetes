---
title: Optimization
---

# Optimization

Our newly built Docker image is ready, but it's not fully optimized for production yet, as it's current size is over 1GB.

We need to make sure that our image is as small as possible, so it can be easily distributed and deployed.

## Reduce number of layers

Each `RUN` instruction in our `Dockerfile` creates a new layer in the image. The more layers we have, the bigger the image will be.

Even if a file is removed in a subsequent layer, it will still be present in the image, as each layer is immutable:

```dockerfile
# Layer 1
RUN echo "Lots of contents [...]" > /tmp/hello.txt

# Layer 2
RUN rm /tmp/hello.txt
```

In the example above, the file `/tmp/hello.txt` will still be present in the image (although not visible), even though it was removed in the second layer.

To reduce the number of layers, we can combine multiple `RUN` instructions into a single one:

```dockerfile
RUN echo "Lots of contents [...]" > /tmp/hello.txt \
    # Do something with the file \
    && rm /tmp/hello.txt
```

## Remove useless files

When building our image, we may have installed some packages or copied some files that are not needed in the final image.

For example, our `vendor` directory may contain development files that are not needed in production:

```shell
$ find vendor/ -type d \( -iname 'test' -o -iname 'tests' \) -exec du -s {} + | awk '{sum += $1} END {print sum}'
213112 # Size of the test directories in kilobytes
```

We have over **200MB** of test files in our `vendor` directory. We can remove them by adding the following line to our `Dockerfile`.

As mentionned before, removing them in a new `RUN` instruction will not reduce the size of the image, as the files will still be present in the previous layer.

Hence, we need to remove them in the same layer as the `composer install` command:

```dockerfile
RUN composer install --no-dev --no-interaction --no-progress --no-suggest \
    # Remove test directories
    && find vendor/ -type d \( -iname 'test' -o -iname 'tests' \) -exec rm -rf {} +
```

> [!WARNING]
> Be careful when removing files, as you may remove files that are needed in production.
> You should check first the list of directories / files that will be removed before running the command, or even better, remove an explicit list of directories.

## Use a smaller base image

The base image we used, `php:8.3.7-fpm-bookworm`, is around **165MB** in size.

We can use a smaller base image, such as `php:8.3.7-fpm-alpine`, which is around **30MB** in size.

However, using a smaller base image may require some changes to our `Dockerfile`, as some packages may not be available in the Alpine image.

Also note that the Alpine image uses `musl` as its standard C library, while the Debian image uses `glibc`. This may cause some issues with some PHP extensions.

`musl` versions of pre-built extensions should be used, as for New Relic one, or the extensions should be compiled from source. 
