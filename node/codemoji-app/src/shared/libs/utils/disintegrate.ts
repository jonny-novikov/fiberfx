const NUM_PARTICLES = 25 // количество частиц для эффекта пепла

export interface DisintegrateOptions {
  /** Длительность анимации в миллисекундах */
  duration?: number
  /** Callback после завершения анимации */
  onComplete?: () => void
  /** Родительский элемент для позиционирования */
  parent?: HTMLElement
}

/**
 * Генерирует серый цвет для частицы (пепел)
 */
function getAshColor(): string {
  const gray = 100 + Math.floor(Math.random() * 60) // от 100 до 160 - более однородный серый
  return `rgb(${gray}, ${gray}, ${gray})`
}

/**
 * Создаёт частицу для эффекта распада
 */
function createParticle(
  x: number,
  y: number,
  size: number,
  color: string,
  parent: HTMLElement
): HTMLElement {
  const particle = document.createElement('div')
  
  particle.style.cssText = `
    position: absolute;
    left: ${x}px;
    top: ${y}px;
    width: ${size}px;
    height: ${size}px;
    background: ${color};
    border-radius: 50%;
    pointer-events: none;
    z-index: 1000;
    opacity: 0.8;
    will-change: transform, opacity;
  `
  
  parent.appendChild(particle)
  return particle
}

/**
 * Анимирует частицу в стиле Таноса (вправо и вверх) - плавно
 */
function animateParticle(particle: HTMLElement, duration: number, index: number, total: number): void {
  // Направление: вправо и вверх с небольшой вариацией
  const progress = index / total // от 0 до 1
  const baseAngle = -Math.PI / 3.5 // примерно -50 градусов (вправо-вверх)
  const angleVariation = (Math.random() - 0.5) * 0.6
  const angle = baseAngle + angleVariation
  
  const distance = 50 + Math.random() * 80
  const tx = Math.cos(angle) * distance + 15
  const ty = Math.sin(angle) * distance - 20
  
  // Плавная задержка - частицы улетают волной слева направо
  const delay = progress * 150 + Math.random() * 80

  // Используем Web Animations API с плавным easing
  particle.animate([
    { 
      transform: 'translate(0, 0) scale(1)', 
      opacity: 0.8
    },
    {
      transform: `translate(${tx * 0.4}px, ${ty * 0.4}px) scale(0.9)`,
      opacity: 0.6,
      offset: 0.35
    },
    {
      transform: `translate(${tx * 0.75}px, ${ty * 0.75}px) scale(0.5)`,
      opacity: 0.3,
      offset: 0.7
    },
    { 
      transform: `translate(${tx}px, ${ty}px) scale(0.1)`, 
      opacity: 0 
    }
  ], {
    duration: duration + Math.random() * 150,
    delay: delay,
    easing: 'cubic-bezier(0.25, 0.1, 0.25, 1)', // очень плавный easing
    fill: 'forwards'
  })
}

/**
 * Применяет эффект распада Таноса к элементу
 */
export function disintegrate(
  element: HTMLElement,
  options: DisintegrateOptions = {}
): void {
  const { duration = 700, onComplete, parent } = options

  try {
    const parentElement = parent || (element.offsetParent as HTMLElement) || element.parentElement
    if (!parentElement) {
      onComplete?.()
      return
    }

    const rect = element.getBoundingClientRect()
    const parentRect = parentElement.getBoundingClientRect()
    
    // Позиция элемента относительно родителя
    const elemX = rect.left - parentRect.left
    const elemY = rect.top - parentRect.top

    // Создаём частицы по всей площади элемента
    const particles: HTMLElement[] = []
    
    for (let i = 0; i < NUM_PARTICLES; i++) {
      // Распределяем частицы по площади элемента (больше справа для эффекта направления)
      const offsetX = Math.random() * rect.width
      const offsetY = Math.random() * rect.height
      const size = 2 + Math.random() * 2.5 // маленькие частицы 2-4.5px
      const color = getAshColor()
      
      const particle = createParticle(
        elemX + offsetX,
        elemY + offsetY,
        size,
        color,
        parentElement
      )
      particles.push(particle)
      
      // Запускаем анимацию - частицы слева стартуют раньше
      animateParticle(particle, duration, i, NUM_PARTICLES)
    }

    // Плавная анимация исчезновения самого элемента
    const elementAnimation = element.animate([
      { opacity: 1, filter: 'blur(0px)', transform: 'scale(1)' },
      { opacity: 0.7, filter: 'blur(0.5px)', transform: 'scale(0.98)', offset: 0.3 },
      { opacity: 0.3, filter: 'blur(1px)', transform: 'scale(0.95)', offset: 0.6 },
      { opacity: 0, filter: 'blur(1.5px)', transform: 'scale(0.9)' }
    ], {
      duration: duration * 0.85,
      easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
      fill: 'forwards'
    })

    // Очищаем после завершения анимации
    const totalDuration = duration + 350
    setTimeout(() => {
      particles.forEach(p => p.remove())
      // Отменяем анимацию чтобы React мог обновить элемент
      elementAnimation.cancel()
      element.style.opacity = ''
      element.style.filter = ''
      element.style.transform = ''
      onComplete?.()
    }, totalDuration)
    
  } catch (error) {
    console.error('Disintegrate effect error:', error)
    onComplete?.()
  }
}

/**
 * Применяет эффект распада к нескольким элементам с задержкой
 */
export function disintegrateMultiple(
  elements: HTMLElement[],
  options: DisintegrateOptions = {}
): void {
  elements.forEach((el, index) => {
    setTimeout(() => {
      disintegrate(el, {
        ...options,
        onComplete: index === elements.length - 1 ? options.onComplete : undefined,
      })
    }, index * 60) // небольшая задержка между элементами
  })
}
