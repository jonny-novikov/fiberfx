const io=new IntersectionObserver(es=>es.forEach(e=>{if(e.isIntersecting)e.target.classList.add('in-view')}),{threshold:.06});
document.querySelectorAll('section .wrap, section .wrap-narrow').forEach(el=>{el.classList.add('reveal-on-scroll');io.observe(el)});

// Tag filtering for the course grid
const fbar=document.querySelector('.filter-bar');
if(fbar){
  const cards=[...document.querySelectorAll('.series-card')];
  fbar.addEventListener('click',e=>{
    const btn=e.target.closest('.filter-btn');if(!btn)return;
    fbar.querySelectorAll('.filter-btn').forEach(b=>{const on=b===btn;b.classList.toggle('active',on);b.setAttribute('aria-pressed',on)});
    const tag=btn.dataset.tag;
    cards.forEach(c=>{const show=tag==='all'||(c.dataset.tags||'').split(' ').includes(tag);c.classList.toggle('filter-hidden',!show)});
  });
}
