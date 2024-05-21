import { defineConfig } from 'vitepress'
import {withMermaid} from "vitepress-plugin-mermaid";

// https://vitepress.dev/reference/site-config
const config = defineConfig({
  title: "Magento Kubernetes",
  description: "The ultimate guide to deploy Magento on Kubernetes",
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
        text: 'Configuration',
        items: [
          { text: 'Environment variables', link: '/guide/configuration/environment-variables' },
        ]
      },
      {
        text: 'Build',
        items: [
          { text: 'Introduction', link: '/guide/build/introduction' },
          { text: 'Docker', link: '/guide/build/docker' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/ClickAndMortar/magento-kubernetes' }
    ],
    footer: {
      message: 'Released under the MIT License.<br/> This project is not affiliated with, endorsed by, or sponsored by Adobe Inc. "Magento" and "Adobe Commerce" are trademarks of Adobe Inc.<br/> All trademarks and registered trademarks are the property of their respective owners.',
      copyright: 'Copyright &copy; 2024-present <a href="https://www.clickandmortar.fr">Click &amp; Mortar</a>'
    }
  },
  head: [['link', { rel: 'icon', href: '/images/logo-transp.png' }]],
  ignoreDeadLinks: true,
  base: '/magento-kubernetes/',
  sitemap: {
    hostname: 'https://clickandmortar.github.io/magento-kubernetes/'
  }
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
