import Chart from 'chart.js/auto';

import { Hook } from './hooks';

export const format = {
  mounted () {
    new Chart(
      (this.el as HTMLCanvasElement).getContext('2d'),
      {
        type: 'pie',
        options: {
          plugins: {
            legend: {
              display: false
            }
          }
        },
        data: {
          labels: [
            'Single', 
            'Pair', 
            'Se-tenant', 
            'Souvenir sheet', 
            'Block', 
            'Plate Block', 
            'ZIP Block', 
            'Mail Early block', 
            'First day cover'
          ],
          datasets: [
            { 
              data: JSON.parse(this.el.dataset.format as string),
              backgroundColor: [
                '#003f5c',
                '#2d4a74',
                '#575387',
                '#825a91',
                '#ac6093',
                '#d1698c',
                '#ed787e',
                '#ff8e6e',
                '#ffd8ca'
              ]
            },
          ]
        }
      }
    );
  }
} as Hook;

export const grade = {
  mounted () {
    new Chart(
      (this.el as HTMLCanvasElement).getContext('2d'),
      {
        type: 'pie',
        options: {
          plugins: {
            legend: {
              display: false
            }
          }
        },
        data: {
          labels: [
            'Ungraded/Below Fine', 
            'Fine', 
            'Fine/Very Fine', 
            'Very Fine', 
            'Very Fine/Extra Fine', 
            'Extra Fine',
            'Extra Fine/Superb',
            'Superb',
            'Gem'
          ],
          datasets: [
            { 
              data: JSON.parse(this.el.dataset.letterGrade as string),
              backgroundColor: [
                '#003f5c',
                '#2d4a74',
                '#575387',
                '#825a91',
                '#ac6093',
                '#d1698c',
                '#ed787e',
                '#ff8e6e',
                '#ffd8ca'
              ]
            },
          ]
        }
      }
    );
  }
} as Hook;

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