import { dataTableInit } from './datatable';
import { disappearingSuccessMessage } from './utils';
import { fileUpload } from './file_upload';
import { modalHook } from './modal';

export interface Hook {
  destroyed: () => void;
  el: HTMLElement;
  mounted: () => void;
  pushEvent: (event: string, params: any) => void;
  pushEventTo: (selector: string | HTMLElement, event: string, params: any) => void;
  updated: () => void;
}

export const Hooks = {
  dataTableInit,
  disappearingSuccessMessage,
  fileUpload,
  modalHook
}