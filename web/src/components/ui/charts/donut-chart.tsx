import React, { forwardRef, useState, useRef } from 'react'
import { cn } from '../../lib'
import { Doughnut } from 'react-chartjs-2'
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend,
} from 'chart.js'

ChartJS.register(
  ArcElement,
  Tooltip,
  Legend
)

export interface DonutChartData {
  label: string
  value: number
  percentage: number
  color: string
}

export interface DonutChartProps
  extends React.HTMLAttributes<HTMLDivElement> {
  title: string
  data: DonutChartData[]
  showMagnifier?: boolean
}

const DonutChart = forwardRef<HTMLDivElement, DonutChartProps>(
  ({ className, title, data, showMagnifier = false, ...props }, ref) => {
    const [tooltip, setTooltip] = useState<{ visible: boolean; x: number; y: number; content: string; color: string }>({
      visible: false,
      x: 0,
      y: 0,
      content: '',
      color: '#000000'
    })
    const chartRef = useRef<ChartJS<'doughnut'> | null>(null)
    
    const percentage = data[0]?.percentage || 0
    const remainingPercentage = 100 - percentage
    
    const chartData = {
      labels: [data[0]?.label || '', 'Restante'],
      datasets: [
        {
          data: [percentage, remainingPercentage],
          backgroundColor: [
            data[0]?.color || '#0066B3',
            'rgba(229, 231, 235, 0.3)' 
          ],
          borderColor: [
            data[0]?.color || '#0066B3',
            'rgba(229, 231, 235, 0.3)'
          ],
          borderWidth: 0,
          borderRadius: 8, 
        }
      ]
    }

    const options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        tooltip: {
          enabled: false
        }
      },
      cutout: '70%',
      rotation: -90,
      circumference: 180,
    }

    const formatValue = (value: number) => {
      return new Intl.NumberFormat('pt-BR').format(value)
    }

    return (
      <div
        ref={ref}
        className={cn(
          'rounded-2xl bg-popover border border-border p-4 sm:p-6 shadow-sm flex flex-col min-h-[280px] transition-all duration-200',
          className
        )}
        {...props}
      >
        <div className="flex items-center justify-center mb-3 sm:mb-4 flex-shrink-0 min-h-[2rem]">
          <h3 className="font-semibold text-foreground leading-tight text-center break-words px-2 text-sm sm:text-base">
            {title}
          </h3>
        </div>
        
        <div className="flex flex-col items-center justify-center flex-1">
          <div className="relative flex-shrink-0 w-full max-w-[200px]" style={{ height: '150px' }}>
            <Doughnut 
              ref={chartRef}
              data={chartData} 
              options={options}
              onMouseMove={(e: React.MouseEvent<HTMLCanvasElement>) => {
                if (!chartRef.current) return
                const elements = (chartRef.current as ChartJS<'doughnut'>).getElementsAtEventForMode(e.nativeEvent, 'nearest', { intersect: true }, true)
                
                if (elements.length > 0 && elements[0].index === 0) {
                  const item = data[0]
                  setTooltip({
                    visible: true,
                    x: e.clientX,
                    y: e.clientY - 50,
                    content: `${item.label}: ${formatValue(item.value)} (${item.percentage}%)`,
                    color: item.color
                  })
                } else {
                  setTooltip({ visible: false, x: 0, y: 0, content: '', color: '#000000' })
                }
              }}
              onMouseLeave={() => {
                setTooltip({ visible: false, x: 0, y: 0, content: '', color: '#000000' })
              }}
            />
            <div className="absolute inset-0 flex items-end justify-center pointer-events-none pb-2">
              <span 
                className="text-xl sm:text-2xl font-bold"
                style={{ color: data[0]?.color }}
              >
                {data[0]?.percentage}%
              </span>
            </div>
          </div>
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

DonutChart.displayName = 'DonutChart'

export { DonutChart }

