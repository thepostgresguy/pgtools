import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';
import CodeBlock from '@theme/CodeBlock';
import styles from './index.module.css';

const principles = [
  {
    title: 'Zero-harm',
    text: 'Every script is read-only and runs with a 5-second statement_timeout and a 3-second lock_timeout, so diagnostics never add load to a struggling server.',
  },
  {
    title: 'No dependencies',
    text: 'Only bash and psql. No Python, Go, or agents to install on a jump host.',
  },
  {
    title: 'Ticket-ready output',
    text: 'Results are formatted to paste straight into Zendesk, Jira, or Markdown.',
  },
  {
    title: 'TimescaleDB aware',
    text: 'Chunk, compression, continuous aggregate, and background job diagnostics sit alongside the general PostgreSQL checks.',
  },
];

const commands = [
  {name: 'locks', to: '/docs/commands/locks', text: 'Current lock contention and blocking queries.'},
  {name: 'activity', to: '/docs/commands/activity', text: 'Running and waiting queries from pg_stat_activity.'},
  {name: 'top-queries', to: '/docs/commands/top-queries', text: 'Most time-consuming queries (needs pg_stat_statements).'},
  {name: 'bloat', to: '/docs/commands/bloat', text: 'Table and index bloat.'},
  {name: 'replication', to: '/docs/commands/replication', text: 'Replication lag and status.'},
  {name: 'cache-hit', to: '/docs/commands/cache-hit', text: 'Table and index cache hit rates.'},
];

const example = `git clone https://github.com/thepostgresguy/pgtools.git
cd pgtools && chmod +x pgtools.sh

./pgtools.sh locks "postgresql://user:pass@host:5432/dbname"`;

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={styles.hero}>
      <div className="container">
        <Heading as="h1">{siteConfig.title}</Heading>
        <p className={styles.tagline}>{siteConfig.tagline}</p>
        <p className={styles.description}>
          A curated set of safe, read-only diagnostic scripts for PostgreSQL and
          TimescaleDB, run through one command-line wrapper. Built for support
          engineers, DBAs, and developers who need to triage a production
          database issue quickly and without making it worse.
        </p>
        <div className={styles.buttons}>
          <Link className="button button--primary button--lg" to="/docs">
            Get Started
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="https://github.com/thepostgresguy/pgtools">
            View on GitHub
          </Link>
        </div>
      </div>
    </header>
  );
}

function Principles() {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className="row">
          {principles.map((p) => (
            <div key={p.title} className="col col--6 margin-bottom--lg">
              <Heading as="h3">{p.title}</Heading>
              <p>{p.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function Commands() {
  return (
    <section className={styles.section}>
      <div className="container">
        <Heading as="h2">When someone says "the database is slow"</Heading>
        <p>
          Start with locks, then activity, then top queries, then cache hit
          rate. Each is one command.
        </p>
        <div className="row">
          {commands.map((c) => (
            <div key={c.name} className="col col--4 margin-bottom--md">
              <Link to={c.to}>
                <code>{c.name}</code>
              </Link>
              <p>{c.text}</p>
            </div>
          ))}
        </div>
        <Link to="/docs/commands">All commands</Link>
      </div>
    </section>
  );
}

function QuickStart() {
  return (
    <section className={styles.section}>
      <div className="container">
        <Heading as="h2">Run your first check</Heading>
        <p>
          Every command takes a connection string or a <code>service=</code>{' '}
          name. Run <code>./pgtools.sh</code> with no arguments to list them all.
        </p>
        <CodeBlock language="bash">{example}</CodeBlock>
      </div>
    </section>
  );
}

export default function Home() {
  return (
    <Layout
      title="Home"
      description="Safe, read-only diagnostic scripts for PostgreSQL and TimescaleDB.">
      <HomepageHeader />
      <main>
        <Principles />
        <Commands />
        <QuickStart />
      </main>
    </Layout>
  );
}
