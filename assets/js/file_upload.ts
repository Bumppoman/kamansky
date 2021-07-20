import { Hook } from './hooks';

export const fileUpload = {
  updated () {
    (this.el.querySelector('.drag-and-drop-file-dropzone') as HTMLElement).classList.add('d-none');
    (this.el.querySelector('.drag-and-drop-file-preview') as HTMLElement).classList.remove('d-none');
  }
} as Hook;