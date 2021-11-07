//import Choices from 'choices.js';

import { Hook } from './hooks';

export const dataTableInit = {
  mounted () {
    const perPageElement = this.el.querySelector('select') as HTMLSelectElement;
    //new Choices(perPageElement, { itemSelectText: '', searchEnabled: false })

    perPageElement.addEventListener('change', event => {
      const perPage = (event.target as HTMLSelectElement).value;
      this.pushEventTo('.kamansky-data-table', 'per_page_changed', { per_page: perPage });
    });
    
    this.applySortStyle(this.el);
  },
  
  updated () {
    this.applySortStyle(this.el);
  },
  
  applySortStyle (element: HTMLElement) {
    const sortColumn = parseInt(element.dataset.sort as string);
    const sortDirection = element.dataset.sortDirection as string;
    
    const table = element.querySelector('table') as HTMLTableElement;
    
    // Apply the sorting icon to the given column header
    for (const [index, header] of ((table.querySelector('tr') as HTMLTableRowElement).querySelectorAll('th')).entries()) {
      if (index == sortColumn) {
        header.classList.add(`sorting-${sortDirection}`);
      }
    }
    
    // Apply the sorting style to the given column
    for (const row of table.querySelectorAll('tr')) {
      for (const [index, column] of row.querySelectorAll('td').entries()) {
        if (index == sortColumn) {
          column.classList.add('sorting');
        } else {
          column.classList.remove('sorting');
        }
      }
    }
  }
} as Hook & { applySortStyle (element: HTMLElement): void };