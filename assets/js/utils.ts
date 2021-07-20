import Choices from 'choices.js';

import { Hook } from './hooks';

export function createDefaultChoices (element: HTMLSelectElement): Choices {
  return new Choices(element, { shouldSort: false });
}

export const disappearingSuccessMessage = {
  mounted () {
    setTimeout(() => this.el.classList.add('hidden'), 5000);
  }
} as Hook;