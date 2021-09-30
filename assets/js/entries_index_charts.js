"use strict"

let myChart;

const entriesChartRawData = document.querySelector("#chart-entries").innerHTML;
const data = JSON.parse(entriesChartRawData);

const barDisplayButton = document.querySelector("#bar_display_button");
const lineDisplayButton = document.querySelector("#line_display_button");
barDisplayButton.addEventListener('click', displayBarChart);
lineDisplayButton.addEventListener('click', displayLineChart);

const redBackGround = 'rgba(200, 0, 0, 0.2)';
const greenBackGround = 'rgba(0, 200, 0, 0.2)';
const blueBackGround = 'rgba(0, 0, 200, 0.2)';
const redBorder = 'rgba(255, 0, 0, 1)';
const greenBorder = 'rgba(0, 255, 0, 1)';
const blueBorder = 'rgba(0, 0, 255, 1)';

const days = data.map(x => x.day);
const weights = data.map(x => x.weight);
const backgroundColors = data.map(x => chooseBackgroundColorFromDelta(x.delta))
const borderColors = data.map(x => chooseBorderColorFromDelta(x.delta))

const lineChart = 'line';
const barChart = 'bar';

function chooseBackgroundColorFromDelta(delta) {
  if (delta > 0) {
    return redBackGround;
  } else if (delta < 0) {
    return greenBackGround;
  } else {
    return blueBackGround;
  }
}

function chooseBorderColorFromDelta(delta) {
  if (delta > 0) {
    return redBorder;
  } else if (delta < 0) {
    return greenBorder;
  } else {
    return blueBorder;
  }   
}

function displayChart(chartType) {
  var ctx = document.getElementById('myChart').getContext('2d');
  var myChart = new Chart(ctx, {
    type: chartType,
    data: {
      labels: days,
      datasets: [{
        label: 'weight',
        data: weights,
        backgroundColor: backgroundColors,
        borderColor: borderColors,
        borderWidth: 1
      }]
    },
    options: {
      scales: {
        y: {
          beginAtZero: false
        }
      }
    }
  });
  return myChart;    
}

function displayLineChart() {
  if (myChart) {
    myChart.destroy();
  }
  myChart = displayChart('line');
}

function displayBarChart() {
  if (myChart) {
    myChart.destroy();
  }
  myChart = displayChart('bar');
}

displayLineChart();



