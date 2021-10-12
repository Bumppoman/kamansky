import { accordionHook } from './accordion';
import { dataTableInit } from './datatable';
import { disappearingSuccessMessage } from './utils';
import { fileUpload } from './file_upload';
import { modalHook } from './modal';
import { grade, hingeQuality } from './trends';

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
  accordionHook,
  dataTableInit,
  disappearingSuccessMessage,
  fileUpload,
  grade,
  hingeQuality,
  modalHook
}