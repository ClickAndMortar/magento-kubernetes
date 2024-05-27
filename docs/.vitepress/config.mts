import { defineConfig } from 'vitepress'
import {withMermaid} from "vitepress-plugin-mermaid";

// https://vitepress.dev/reference/site-config
const config = defineConfig({
  title: "Magento Kubernetes",
  description: "The ultimate guide to deploy Magento on Kubernetes",
  lastUpdated: true,
  themeConfig: {
    logo: '/images/logo-transp.png',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/introduction' }
    ],
    sidebar: [
      { text: 'Introduction', link: '/guide/introduction' },
      { text: 'Requirements', link: '/guide/requirements' },
      {
        text: '📚 Preparation',
        collapsed: false,
        items: [
          { text: 'Environment variables', link: '/guide/preparation/environment-variables' },
          { text: 'Configuration', link: '/guide/preparation/configuration' },
          { text: 'Secrets', link: '/guide/preparation/secrets' },
        ]
      },
      {
        text: '⚙️ Build',
        collapsed: false,
        items: [
          { text: 'Introduction', link: '/guide/build/introduction' },
          { text: 'Docker image', link: '/guide/build/docker' },
          { text: 'New Relic', link: '/guide/build/newrelic' },
          { text: 'Optimization', link: '/guide/build/optimization' },
          { text: 'Security', link: '/guide/build/security' },
        ]
      },
      {
        text: '🚀 Deployment',
        collapsed: false,
        items: [
          { text: 'Introduction', link: '/guide/deployment/introduction' },
          { text: 'External services', link: '/guide/deployment/external-services' },
          { text: 'Architecture', link: '/guide/deployment/architecture' },
          { text: 'Resources and scaling', link: '/guide/deployment/resources-scaling' },
          { text: 'Helm chart', link: '/guide/deployment/helm-chart' },
          { text: 'CI/CD 🚧', link: '/guide/deployment/ci-cd' },
        ]
      },
      {
        text: '💡 Advanced',
        collapsed: false,
        items: [
          { text: 'High availability', link: '/guide/advanced/high-availability' },
          { text: 'ARM64 architecture', link: '/guide/advanced/arm64-architecture' },
          { text: 'Spot / preemptible instances', link: '/guide/advanced/spot-preemptible-instances' },
          { text: 'Monitoring 🚧', link: '/guide/advanced/monitoring' },
          { text: 'Log management 🚧', link: '/guide/advanced/log-management' },
          { text: 'Read-only filesystem 🚧', link: '/guide/advanced/read-only-filesystem' },
          { text: 'Amazon S3 Media storage 🚧', link: '/guide/advanced/amazon-s3-media-storage' },
        ]
      },
      {
        text: '🧩 Modules',
        collapsed: false,
        items: [
          { text: 'Selection', link: '/guide/modules/selection' }
        ]
      }
    ],
    editLink: {
      pattern: 'https://github.com/ClickAndMortar/magento-kubernetes/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ClickAndMortar/magento-kubernetes' }
    ],
    footer: {
      message: 'Released under the MIT License.<br/> This project is not affiliated with, endorsed by, or sponsored by Adobe Inc. "Magento" and "Adobe Commerce" are trademarks of Adobe Inc.<br/> All trademarks and registered trademarks are the property of their respective owners.',
      copyright: 'Copyright &copy; 2024-present <a href="https://www.clickandmortar.fr">Click &amp; Mortar</a>'
    },
    search: {
      provider: 'local',
    }
  },
  head: [['link', { rel: 'icon', href: '/magento-kubernetes/images/logo-transp.png' }]],
  ignoreDeadLinks: true,
  base: '/magento-kubernetes/',
  sitemap: {
    hostname: 'https://clickandmortar.github.io/magento-kubernetes/'
  },
})

export default withMermaid({
  ...config,
  mermaid: {
    // refer https://mermaid.js.org/config/setup/modules/mermaidAPI.html#mermaidapi-configuration-defaults for options
  },
  // optionally set additional config for plugin itself with MermaidPluginConfig
  mermaidPlugin: {
    class: 'mermaid', // set additional css classes for parent container
  },
})
