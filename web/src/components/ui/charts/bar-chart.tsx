import React, { forwardRef, useRef, useState } from 'react'
import { cn } from '../../lib'
import { Bar } from 'react-chartjs-2'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
)

export interface BarChartData {
  label: string
  previousPeriod: number
  selectedPeriod: number
}

export interface BarChartProps
  extends React.HTMLAttributes<HTMLDivElement> {
  title: string
  data: BarChartData
  maxValue?: number
  showLegend?: boolean
  colorScheme?: 'blue-green' | 'pink-blue'
  isCurrency?: boolean
}

const BarChart = forwardRef<HTMLDivElement, BarChartProps>(
  ({ className, title, data, maxValue, showLegend = true, colorScheme = 'blue-green', isCurrency = false, ...props }, ref) => {
    const [tooltip, setTooltip] = useState<{ visible: boolean; x: number; y: number; content: string; color: string }>({
      visible: false,
      x: 0,
      y: 0,
      content: '',
      color: '#000000'
    })
    const chartRef = useRef<ChartJS<'bar'> | null>(null)
    
    const colors = {
      'blue-green': {
        previous: '#3b82f6',
        selected: '#10b981'
      },
      'pink-blue': {
        previous: '#ec4899',
        selected: '#1e40af'
      }
    }

    const currentColors = colors[colorScheme]
    
    const previousValue = parseFloat(data.previousPeriod.toString()) || 0
    const selectedValue = parseFloat(data.selectedPeriod.toString()) || 0
    
    const validPrevious = isNaN(previousValue) || !isFinite(previousValue) ? 0 : previousValue
    const validSelected = isNaN(selectedValue) || !isFinite(selectedValue) ? 0 : selectedValue
    
    const calculatedMax = Math.max(validPrevious, validSelected) * 1.2
    const finalMaxValue = maxValue || (calculatedMax > 0 ? calculatedMax : 100)

    const formatValue = (value: number) => {
      if (isCurrency) {
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value)
      }
      if (value >= 1000000000) return `${(value / 1000000000).toFixed(1)}B`
      if (value >= 1000000) return `${(value / 1000000).toFixed(1)}M`
      if (value >= 1000) return `${(value / 1000).toFixed(0)}k`
      return value.toFixed(0)
    }

    const chartData = {
      labels: [title],
      datasets: [
        {
          label: 'Período Anterior',
          data: [validPrevious],
          backgroundColor: currentColors.previous,
          borderColor: currentColors.previous,
          borderWidth: 1,
          borderRadius: 4,
        },
        {
          label: 'Período Selecionado',
          data: [validSelected],
          backgroundColor: currentColors.selected,
          borderColor: currentColors.selected,
          borderWidth: 1,
          borderRadius: 4,
        }
      ]
    }

    const options = {
      responsive: true,
      maintainAspectRatio: false,
      layout: {
        padding: {
          left: 0,
          right: 0,
          top: 0,
          bottom: 0
        }
      },
      interaction: {
        intersect: false,
        mode: 'index' as const
      },
      plugins: {
        legend: {
          display: showLegend,
          position: 'bottom' as const,
          align: 'start' as const,
          labels: {
            usePointStyle: true,
            padding: 15,
            font: {
              size: 12
            }
          }
        },
        tooltip: {
          enabled: false
        }
      },
      scales: {
        x: {
          display: false,
          grid: {
            display: false
          },
          ticks: {
            display: false
          }
        },
        y: {
          beginAtZero: true,
          max: finalMaxValue,
          grid: {
            display: true,
            color: 'rgba(0, 0, 0, 0.1)'
          },
          ticks: {
            callback: function(value: string | number) {
              const numValue = typeof value === 'string' ? parseFloat(value) : value
              if (isNaN(numValue) || !isFinite(numValue)) return '0'
              return formatValue(numValue)
            },
            maxTicksLimit: 6
          }
        }
      }
    }

    return (
      <div
        ref={ref}
        className={cn(
          'rounded-2xl border-2 border-border bg-popover p-3 sm:p-4 shadow-sm flex flex-col h-[280px] 2xl:h-[350px] transition-all duration-200',
          className
        )}
        {...props}
      >
        <h3 className="flex-shrink-0 mb-2 font-semibold leading-tight break-words text-foreground sm:mb-3 text-sm sm:text-base">
          {title}
        </h3>
        
        <div className="flex-1 h-[200px] 2xl:h-[270px] overflow-visible">
          <Bar 
            ref={chartRef}
            data={chartData} 
            options={options}
            onMouseMove={(e: React.MouseEvent<HTMLCanvasElement>) => {
              if (!chartRef.current) return;
              
              const elements = (chartRef.current as ChartJS<'bar'>).getElementsAtEventForMode(e.nativeEvent, 'nearest', { intersect: true }, true);
              
              if (elements.length > 0) {
                const element = elements[0];
                const datasetIndex = element.datasetIndex;
                const rawValue = datasetIndex === 0 ? data.previousPeriod : data.selectedPeriod;
                const value = formatValue(rawValue);
                const label = datasetIndex === 0 ? 'Período Anterior' : 'Período Selecionado';
                const color = datasetIndex === 0 ? currentColors.previous : currentColors.selected;
                
                setTooltip({
                  visible: true,
                  x: e.clientX,
                  y: e.clientY - 50,
                  content: `${label}: ${value}`,
                  color: color
                });
              } else {
                setTooltip({ visible: false, x: 0, y: 0, content: '', color: '#000000' });
              }
            }}
            onMouseLeave={() => {
              setTooltip({ visible: false, x: 0, y: 0, content: '', color: '#000000' });
            }}
          />
        </div>
        
        {tooltip.visible && (
          <div
            style={{
              position: 'fixed',
              left: tooltip.x,
              top: tooltip.y,
              zIndex: 99999999,
              backgroundColor: 'rgba(255, 255, 255, 0.95)',
              color: 'black',
              padding: '8px 12px',
              borderRadius: '6px',
              fontSize: '12px',
              pointerEvents: 'none',
              border: `2px solid ${tooltip.color}`,
              boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)'
            }}
          >
            {tooltip.content}
          </div>
        )}
      </div>
    )
  }
)

BarChart.displayName = 'BarChart'

export { BarChart }

