import { Hook } from './hooks';

export const successMessage = {
  updated () {
    this.el.dispatchEvent(new CustomEvent('kamansky:successMessageUpdated'));
  }
} as Hook;