import { dataTableInit } from './datatable';
import { fileUpload } from './fileUpload';
import { modalInit } from './modal';
import { format, grade, hingeQuality } from './trends';
import { successMessage } from './successMessage';

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
  dataTableInit,
  fileUpload,
  format,
  grade,
  hingeQuality,
  modalInit,
  successMessage
}