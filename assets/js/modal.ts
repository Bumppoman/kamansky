import { Modal } from 'bootstrap';
import Choices from 'choices.js';

import { Hook } from './hooks';
import { createDefaultChoices } from './utils';

export const modalHook = {
  _choicesInstances: new Map(),
  
  mounted () {
    Modal.getOrCreateInstance(this.el).show();
    
    for (const select of this.el.querySelectorAll('.choices-select')) {
      this._choicesInstances.set(select.id, createDefaultChoices(select as HTMLSelectElement));
    }
    
    for (const closeElement of this.el.querySelectorAll('.close-modal')) {
      closeElement.addEventListener('click', event => {
        event.preventDefault();
        Modal.getInstance(this.el)?.hide();
      });
    }
    
    this.el.addEventListener('hidden.bs.modal', this._pushClose.bind(this));
    
    this.handleEvent('kamansky:modal:disableChoices', ({field}) => {
      this._choicesInstances.get(field as String)?.disable();
    });
    
    this.handleEvent('kamansky:modal:enableChoices', ({field}) => {
      this._choicesInstances.get(field as String)?.enable();
    });
  },
  
  destroyed () {
    this.el.removeEventListener('hidden.bs.modal', this._pushClose.bind(this));
    Modal.getInstance(this.el)?.hide();
  },
  
  updated () {
    this.el.classList.add('show');
    this.el.style.display = 'block';
  },
  
  _pushClose (event: Event) {
    this.pushEventTo(this.el, 'close', []);
  }
} as Hook & { _pushClose (event: Event): void; _choicesInstances: Map<String,Choices> };