(() => {
  const root = document.getElementById('coupon-offers');
  if (!root || !location.pathname.startsWith('/portal/')) return;
  const corner = root.querySelector('.offer-corner');
  const cornerClock = corner.querySelector('[data-offer-clock]');
  const selectedLabel = corner.querySelector('[data-offer-selected]');
  const dialog = root.querySelector('dialog');
  const close = dialog.querySelector('.offer-close');
  const template = root.querySelector('template');
  const list = dialog.querySelector('.offer-list');
  const icons = {classic: '🎟️', black_friday: '🛍️', nowruz: '🌱', yalda: '🍉', christmas: '🎄'};
  const page = location.pathname.replace(/\/$/, '');
  const url = new URL(location.href);
  let linked = url.searchParams.get('offer');
  let offers = [];
  let visible = [];
  let user = '';
  let selected = '';
  let applied = '';
  let offset = 0;
  let refreshTimer;
  let loading = false;
  const seen = new Set();
  const locale = (root.dataset.locale || document.documentElement.lang || 'en').replace('_', '-');
  const number = new Intl.NumberFormat(locale, {useGrouping: false});
  const padded = new Intl.NumberFormat(locale, {minimumIntegerDigits: 2, useGrouping: false});
  const percent = new Intl.NumberFormat(locale, {style: 'percent', maximumFractionDigits: 2});

  function read(storage, key) {
    try { return window[storage].getItem(key); } catch (error) { return null; }
  }

  function write(storage, key, value) {
    try { window[storage].setItem(key, value); } catch (error) { /* Keep the current page usable. */ }
  }

  function seenKey(offer) {
    return 'coupon-offer-seen:' + user + ':' + offer.id + ':' + offer.start;
  }

  function timeLeft(offer) {
    return offer.end - Math.floor((Date.now() + offset) / 1000);
  }

  function clock(offer) {
    const time = Math.max(0, timeLeft(offer));
    const hours = Math.floor(time / 3600);
    return [number.format(hours), padded.format(Math.floor(time / 60) % 60), padded.format(time % 60)].join(':');
  }

  function applySelection() {
    const offer = visible.find(item => item.id === selected);
    const key = offer ? offer.id + ':' + offer.start + ':' + offer.code : '';
    if (typeof window.setCheckoutOffer === 'function' && key !== applied) {
      applied = key;
      window.setCheckoutOffer(offer || null);
    }
  }

  function select(offer) {
    if (timeLeft(offer) <= 0) return;
    selected = offer.id;
    write('sessionStorage', 'coupon-offer:' + user, selected);
    if (dialog.open) dialog.close();
    if (page === '/portal/plans' || typeof window.setCheckoutOffer === 'function') {
      tick();
      return;
    }
    // The ID also carries the choice when browser storage is unavailable.
    location.assign('/portal/plans?offer=' + encodeURIComponent(offer.id));
  }

  window.clearCheckoutOffer = () => {
    selected = applied = '';
    write('sessionStorage', 'coupon-offer:' + user, '');
    tick();
  };
  window.checkoutOfferExpired = offer => {
    const current = offers.find(item => item.id === offer.id && item.start === offer.start);
    return !current || timeLeft(current) <= 0;
  };

  function theme(element, offer) {
    element.dataset.offerTheme = offer.theme;
    element.querySelector('.offer-icon').textContent = icons[offer.theme] || icons.classic;
  }

  function render() {
    const chosen = visible.find(item => item.id === selected);
    if (page === '/portal/plans') {
      document.querySelectorAll('a[href^="/portal/plan/details?"]').forEach(link => {
        const destination = new URL(link.href);
        if (chosen) destination.searchParams.set('offer', chosen.id);
        else destination.searchParams.delete('offer');
        link.setAttribute('href', destination.pathname + destination.search);
      });
    }
    const featured = chosen || visible[0];
    root.hidden = !featured;
    if (!featured) {
      if (dialog.open) dialog.close();
      return;
    }
    theme(corner, featured);
    corner.querySelector('strong').textContent = featured.title;
    selectedLabel.hidden = !chosen;
    selectedLabel.textContent = root.dataset.applied;
    const count = corner.querySelector('.offer-count');
    count.hidden = visible.length < 2;
    count.textContent = number.format(visible.length);
    list.replaceChildren();
    visible.forEach(offer => {
      const card = template.content.firstElementChild.cloneNode(true);
      theme(card, offer);
      card.querySelector('h3').textContent = offer.title;
      const discount = card.querySelector('[data-offer-percent]');
      if (discount && typeof offer.percent === 'number' && offer.percent > 0) {
        discount.textContent = percent.format(offer.percent / 100);
        discount.hidden = false;
      }
      const button = card.querySelector('.offer-use');
      button.textContent = root.dataset.use;
      button.addEventListener('click', () => select(offer));
      list.append(card);
    });
  }

  let rendered = '';
  function tick() {
    visible = offers.filter(offer => timeLeft(offer) > 0);
    const key = JSON.stringify([selected, visible]);
    if (key !== rendered) {
      rendered = key;
      render();
    }
    if (visible.length) {
      cornerClock.textContent = clock(visible.find(item => item.id === selected) || visible[0]);
      visible.forEach((offer, index) => {
        list.children[index].querySelector('[data-offer-clock]').textContent = clock(offer);
      });
    }
    applySelection();
  }

  function open() {
    if (dialog.open || !visible.length) return;
    dialog.showModal();
    visible.forEach(offer => {
      const key = seenKey(offer);
      seen.add(key);
      write('localStorage', key, '1');
    });
  }

  corner.addEventListener('click', open);
  close.addEventListener('click', () => dialog.close());
  dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });

  async function refresh() {
    if (loading || document.hidden) return;
    clearTimeout(refreshTimer);
    loading = true;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    let delay = 45000;
    try {
      const response = await fetch('/xmplus-patch.php?do=couponcampaign.active', {signal: controller.signal});
      if (response.status === 403) {
        offers = [];
        tick();
        return;
      }
      const data = await response.json();
      if (!data.ok) return;
      if (String(data.user) !== user) {
        user = String(data.user);
        selected = read('sessionStorage', 'coupon-offer:' + user) || '';
      }
      offers = data.offers;
      offset = data.now * 1000 - Date.now();
      if (linked) {
        if (offers.some(offer => offer.id === linked)) {
          selected = linked;
          write('sessionStorage', 'coupon-offer:' + user, selected);
        }
        linked = null;
        url.searchParams.delete('offer');
        history.replaceState(history.state, '', url);
      }
      tick();
      const canInterrupt = !/^\/portal\/(plan\/details|checkout|order)(\/|$)/.test(page);
      if (canInterrupt && !visible.some(offer => offer.id === selected) && !document.querySelector('.swal2-container, .modal.show')
          && visible.some(offer => !seen.has(seenKey(offer)) && !read('localStorage', seenKey(offer)))) open();
      if (data.next) delay = Math.min(delay, Math.max(1000, (data.next - data.now) * 1000));
    } catch (error) {
      // Retry the feed while continuing the last known deadlines locally.
    } finally {
      clearTimeout(timeout);
      loading = false;
      refreshTimer = setTimeout(refresh, delay);
    }
  }

  document.addEventListener('visibilitychange', refresh);
  setInterval(tick, 1000);
  refresh();
})();
