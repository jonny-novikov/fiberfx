const cx = (...xs) => xs.filter(Boolean).join(' ');

const MkIcon = ({ name, size = 20 }) => (
  <img
    src={`https://cdn.jsdelivr.net/npm/lucide-static@latest/icons/${name}.svg`}
    width={size} height={size} alt=""
    style={{ display: 'block' }}
  />
);

const MkButton = ({ variant = 'fill', size = 'md', children, onClick, href }) => {
  const cls = cx('mk-btn', `mk-btn-${variant}`, `mk-btn-${size}`);
  if (href) return <a className={cls} href={href} onClick={onClick}>{children}</a>;
  return <button className={cls} onClick={onClick}>{children}</button>;
};

const MkNav = ({ onGetStarted }) => (
  <nav className="mk-nav">
    <div className="mk-nav-inner">
      <a className="mk-brand" href="#">
        <img className="mk-brand-mark" src="../../packages/mercury-ds/project/assets/mercury-logo.png" alt="" aria-hidden="true" />
        <img src="../../packages/mercury-ds/project/assets/logo-wordmark.svg" alt="Mercury" />
      </a>
      <div className="mk-nav-links">
        <a href="#product">Product</a>
        <a href="#features">Features</a>
        <a href="#pricing">Pricing</a>
        <a href="#company">Company</a>
        <a href="#docs">Docs</a>
      </div>
      <div className="mk-nav-cta">
        <MkButton variant="ghost" size="sm">Sign in</MkButton>
        <MkButton variant="dark" size="sm" onClick={onGetStarted}>Get started</MkButton>
      </div>
    </div>
  </nav>
);

const MkHero = ({ onGetStarted }) => (
  <section className="mk-hero">
    <div>
      <div className="mk-eyebrow">
        <span className="tag">New</span> Mercury Wallet 3.0 is live
      </div>
      <h1 className="mk-h1">Money that moves <em>quietly</em>, at the speed of a thought.</h1>
      <p className="mk-lede">
        Mercury is a calm, considered money app. Send, receive, and hold across currencies
        with a product designed for the people who would rather not think about their bank.
      </p>
      <div className="mk-hero-ctas">
        <MkButton size="lg" onClick={onGetStarted}>Get started — it's free</MkButton>
        <MkButton size="lg" variant="outline">See the product tour</MkButton>
      </div>
      <div className="mk-hero-meta">
        <span>No monthly fee</span>
        <span>·</span>
        <span>Available in 38 countries</span>
        <span>·</span>
        <span>4.8 on the App Store</span>
      </div>
    </div>
    <div className="mk-hero-visual">
      <div className="mk-hero-card one">
        <h4>Available balance</h4>
        <div className="big">$4,218.40</div>
        <div style={{ marginTop: 10, font: '500 13px/1 var(--font-primary)', opacity: 0.85 }}>+$128.20 this week</div>
      </div>
      <div className="mk-hero-card two">
        <h4>Recent</h4>
        <div className="row">Ana Reyes <span className="meta">Today</span></div>
        <div className="row">Top up · Visa <b>+$500.00</b></div>
        <div className="row">Refund · Uber <b>+$12.80</b></div>
      </div>
    </div>
  </section>
);

const MkLogos = () => (
  <div className="mk-logos">
    <span className="lab">Trusted by modern teams</span>
    <span className="logo">Linear</span>
    <span className="logo">Arc</span>
    <span className="logo">Notion</span>
    <span className="logo">Ramp</span>
    <span className="logo">Vercel</span>
    <span className="logo">Figma</span>
  </div>
);

const Feature = ({ icon, title, children }) => (
  <div className="mk-feature">
    <div className="mk-feature-ic"><MkIcon name={icon} size={22} /></div>
    <h3>{title}</h3>
    <p>{children}</p>
  </div>
);

const MkFeatures = () => (
  <section className="mk-section" id="features">
    <div className="mk-section-inner">
      <div className="mk-kicker">What's inside</div>
      <h2 className="mk-h2">Every money tool, at the same rhythm.</h2>
      <p className="mk-sublede">
        A small set of features, each considered. Designed around the way you actually think about money —
        not the way banks want to organise it.
      </p>
      <div className="mk-features">
        <Feature icon="arrow-up-right" title="Instant transfers">
          Send across 38 currencies in seconds. No fees under $500 per month, mid-market rate always.
        </Feature>
        <Feature icon="shield-check" title="Security, built in">
          Biometric confirmation, hardware-backed keys, and transaction-level consent. Nothing moves by accident.
        </Feature>
        <Feature icon="piggy-bank" title="Pockets &amp; goals">
          Quietly set aside for rent, travel, a new home. Pockets auto-fill with the rules you write once.
        </Feature>
        <Feature icon="bar-chart-3" title="Clear cashflow">
          One honest graph. See what came in, what went out, what's regular — no dashboard overwhelm.
        </Feature>
        <Feature icon="credit-card" title="Cards that understand limits">
          Virtual and physical cards with per-merchant rules. Pause anything, any time, without a hold queue.
        </Feature>
        <Feature icon="globe" title="Travel-ready">
          Hold balance in 38 currencies. Spend locally at the real rate. No surprise fees at the airport.
        </Feature>
      </div>
    </div>
  </section>
);

const MkPricing = ({ onGetStarted }) => (
  <section className="mk-section alt" id="pricing">
    <div className="mk-section-inner">
      <div className="mk-kicker">Pricing</div>
      <h2 className="mk-h2">Fair, flat, and mostly free.</h2>
      <p className="mk-sublede">Start on Personal. Move up when your life (or your team) grows into it.</p>
      <div className="mk-price-grid">
        <div className="mk-price">
          <div className="mk-price-name">Personal</div>
          <div className="mk-price-num">$0 <span>/ month</span></div>
          <p className="mk-price-desc">Everything an individual needs to stop thinking about their bank.</p>
          <ul className="mk-price-list">
            <li>Send up to $500 / mo with no fee</li>
            <li>One virtual card</li>
            <li>Pockets &amp; goals</li>
            <li>Mid-market exchange rate</li>
          </ul>
          <div className="mk-price-cta"><MkButton variant="outline" size="md" onClick={onGetStarted}>Start free</MkButton></div>
        </div>
        <div className="mk-price is-feat">
          <div className="mk-price-name">Plus</div>
          <div className="mk-price-num">$9 <span>/ month</span></div>
          <p className="mk-price-desc">For people who move across currencies and want more cards.</p>
          <ul className="mk-price-list">
            <li>Unlimited fee-free transfers</li>
            <li>Up to 10 virtual cards</li>
            <li>Physical metal card included</li>
            <li>Priority support under 1 hr</li>
          </ul>
          <div className="mk-price-cta"><MkButton variant="fill" size="md" onClick={onGetStarted}>Start 30-day trial</MkButton></div>
        </div>
        <div className="mk-price">
          <div className="mk-price-name">Teams</div>
          <div className="mk-price-num">$19 <span>/ seat / mo</span></div>
          <p className="mk-price-desc">Small teams and founders who share balance sheets.</p>
          <ul className="mk-price-list">
            <li>Shared pockets and rules</li>
            <li>Role-based approvals</li>
            <li>Xero &amp; QuickBooks sync</li>
            <li>Dedicated CS manager</li>
          </ul>
          <div className="mk-price-cta"><MkButton variant="outline" size="md">Talk to us</MkButton></div>
        </div>
      </div>
    </div>
  </section>
);

const MkQuote = () => (
  <section className="mk-section dark">
    <div className="mk-section-inner mk-quote-wrap">
      <div className="mk-kicker" style={{ color: 'rgb(var(--iris-11))' }}>What people say</div>
      <blockquote className="mk-quote">
        "It's the first money app I've opened and not felt a little bit worse. Everything is where
        I expect, and the moments that used to take ten taps now take two."
      </blockquote>
      <div className="mk-quote-by">
        <div className="mk-quote-av">MK</div>
        <div>
          <div className="mk-quote-name">Mira Kowalski</div>
          <div className="mk-quote-role">Designer · Warsaw</div>
        </div>
      </div>
    </div>
  </section>
);

const MkCta = ({ onGetStarted }) => (
  <section className="mk-section">
    <div className="mk-cta-banner">
      <div>
        <h2>Spend less time on your money.</h2>
        <p>Set up Mercury in about two minutes. No paperwork, no queues, no holds.</p>
      </div>
      <div className="mk-cta-actions">
        <MkButton size="lg" variant="fill" onClick={onGetStarted}>Create account</MkButton>
        <MkButton size="lg" variant="ghost" style={{ color: '#fff' }}>Read the docs</MkButton>
      </div>
    </div>
  </section>
);

const MkFooter = () => (
  <footer className="mk-footer">
    <div className="mk-footer-inner">
      <div className="mk-footer-col">
        <a className="mk-brand" href="#">
          <img className="mk-brand-mark" src="../../packages/mercury-ds/project/assets/mercury-logo.png" alt="" aria-hidden="true" style={{ height: 26 }} />
          <img src="../../packages/mercury-ds/project/assets/logo-wordmark.svg" style={{ height: 26 }} alt="Mercury" />
        </a>
        <p className="mk-footer-bio">A money app for people who would rather not think about their bank. Made quietly, on purpose.</p>
      </div>
      <div className="mk-footer-col">
        <h5>Product</h5>
        <a href="#">Personal</a><a href="#">Plus</a><a href="#">Teams</a><a href="#">Cards</a><a href="#">Pockets</a>
      </div>
      <div className="mk-footer-col">
        <h5>Company</h5>
        <a href="#">About</a><a href="#">Careers</a><a href="#">Press</a><a href="#">Contact</a>
      </div>
      <div className="mk-footer-col">
        <h5>Resources</h5>
        <a href="#">Docs</a><a href="#">Security</a><a href="#">Status</a><a href="#">Changelog</a>
      </div>
    </div>
    <div className="mk-footer-legal">
      <span>© 2026 Mercury, Inc.</span>
      <span>Made with care in Lisbon, New York and Singapore.</span>
    </div>
  </footer>
);

const MkSignup = ({ open, onClose }) => {
  const [email, setEmail] = React.useState('');
  const [sent, setSent] = React.useState(false);
  if (!open) return null;
  return (
    <div className="mk-modal-backdrop" onClick={onClose}>
      <div className="mk-modal mk-anchor" onClick={e => e.stopPropagation()}>
        <button className="mk-modal-close" onClick={onClose}><MkIcon name="x" size={18} /></button>
        {sent ? (
          <>
            <h3>You're on the list.</h3>
            <p>We'll be in touch at {email} with your invite.</p>
            <div className="mk-modal-actions">
              <MkButton variant="fill" size="md" onClick={onClose}>Close</MkButton>
            </div>
          </>
        ) : (
          <>
            <h3>Start with Mercury.</h3>
            <p>Takes about two minutes. We'll send a magic link to your email.</p>
            <div className="mk-modal-field">
              <label>Email address</label>
              <input value={email} onChange={e => setEmail(e.target.value)} placeholder="you@example.com" />
            </div>
            <div className="mk-modal-actions">
              <MkButton variant="outline" size="md" onClick={onClose}>Cancel</MkButton>
              <MkButton variant="fill" size="md" onClick={() => setSent(true)} style={{ flex: 1 }}>Send magic link</MkButton>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

Object.assign(window, {
  MkIcon, MkButton, MkNav, MkHero, MkLogos, MkFeatures, MkPricing, MkQuote, MkCta, MkFooter, MkSignup,
});
