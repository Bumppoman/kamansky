import { Modal } from 'bootstrap';

import { Hook } from './hooks';
import { createDefaultChoices } from './utils';

export const modalHook = {
  mounted () {
    Modal.getOrCreateInstance(this.el).show();
    
    for (const select of this.el.querySelectorAll('.choices-select')) {
      createDefaultChoices(select as HTMLSelectElement);
    }
    
    for (const closeElement of this.el.querySelectorAll('.close-modal')) {
      closeElement.addEventListener('click', event => {
        event.preventDefault();
        Modal.getInstance(this.el)?.hide();
      });
    }
    
    this.el.addEventListener('hidden.bs.modal', this._pushClose.bind(this));
  },
  
  destroyed () {
    this.el.removeEventListener('hidden.bs.modal', this._pushClose.bind(this));
    //this.modalInstance.hide();
    Modal.getInstance(this.el)?.hide();
  },
  
  _pushClose (event: Event) {
    this.pushEventTo(this.el, 'close', []);
  }
} as Hook & { _pushClose (event: Event): void; };