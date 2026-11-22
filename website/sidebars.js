/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  tutorialSidebar: [
    'intro',
    'getting-started',
    {
      type: 'category',
      label: 'Commands',
      link: {type: 'doc', id: 'commands/index'},
      items: [
        'commands/locks',
        'commands/activity',
        'commands/top-queries',
        'commands/bloat',
        'commands/replication',
        'commands/disk-usage',
        'commands/cache-hit',
        'commands/chunk-stats',
        'commands/compression-stats',
        'commands/cagg-stats',
        'commands/job-errors',
        'commands/uncompressed-chunks',
        'commands/permissions',
        'commands/ownership',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: ['guides/incident-response'],
    },
  ],
};

export default sidebars;
