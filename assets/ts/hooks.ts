import { fileUpload } from './fileUpload';
import { flash } from './flash';
import { modalInit } from './modal';
import { format, grade, hingeQuality } from './trends';

export interface Hook {
  beforeUpdate: () => void;
  destroyed: () => void;
  el: HTMLElement;
  handleEvent: (eventName: string, callback: (...args: any[]) => void) => void;
  mounted: () => void;
  pushEvent: (event: string, params: any) => void;
  pushEventTo: (selector: string | HTMLElement, event: string, params: any) => void;
  updated: () => void;
}

export const Hooks = {
  fileUpload,
  flash,
  format,
  grade,
  hingeQuality,
  modalInit
}