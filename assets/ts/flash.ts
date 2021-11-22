import { Hook } from './hooks';

export const flash = {
  mounted () {
    this.el.addEventListener('kamansky:clear-flash', () => {
      this.pushEvent('lv:clear-flash', []);
    });
  },

  updated () {
    this.el.dispatchEvent(new CustomEvent('kamansky:flashUpdated'));
  }
} as Hook;