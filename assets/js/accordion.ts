import { Hook } from './hooks';

export const accordionHook = {
  mounted () {
    this.el.addEventListener('show.bs.collapse', this._show.bind(this));
  },
  
  destroyed () {
    this.el.removeEventListener('show.bs.collapse', this._show.bind(this));
  },
  
  _show (event: Event) {
    this.pushEvent('show', this.el.dataset)
  }
} as Hook & { _show (event: Event): void; };