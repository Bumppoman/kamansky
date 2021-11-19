import { Hook } from './hooks';

export const flash = {
  updated () {
    this.el.dispatchEvent(new CustomEvent('kamansky:flashUpdated'));
  }
} as Hook;