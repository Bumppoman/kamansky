import { Hook } from './hooks';

export const fileUpload = {
  updated () {
    (this.el.querySelector('.drag-and-drop-file-dropzone') as HTMLElement).classList.add('hidden');
    (this.el.querySelector('.drag-and-drop-file-preview') as HTMLElement).classList.remove('hidden');
  }
} as Hook;