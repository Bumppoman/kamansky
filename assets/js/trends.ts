import Chart from 'chart.js/auto';

import { Hook } from './hooks';

export const hingeQuality = {
  mounted () {
    new Chart(
      (this.el as HTMLCanvasElement).getContext('2d'),
      {
        type: 'pie',
        data: {
          labels: ['Never Hinged', 'Hinged'],
          datasets: [
            { 
              data: [
                this.el.dataset.neverHinged, 
                this.el.dataset.hinged
              ],
              backgroundColor: [
                '#264475',
                '#e65245'
              ]
            },
          ]
        }
      }
    );
  }
} as Hook;