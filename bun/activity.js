import '@mariohamann/activity-graph'

const DEFAULT_CONFIG = {
    activityLevels: [0, 1, 3, 5, 8],
    colors: [
        '#ebedf0', // No activity
        '#9be9a8', // Light green
        '#40c463', // Medium green
        '#30a14e', // Dark green
        '#216e39', // Darkest green
    ],
    dateFormat: 'YYYY-MM-DD',
    firstDayOfWeek: 1,
    maxItems: 8,
}

// GitHub-style habit tracker for learning diary
function initTracker(userConfig = {}) {
    const config = { ...DEFAULT_CONFIG, ...userConfig }
    // Ensure activity-graph component is defined
    if (!customElements.get('activity-graph')) {
        console.error('activity-graph component not registered')
        return
    }

    // Wait for markdown content using MutationObserver
    if (!document.querySelector('.markdownit li')) {
        const observer = new MutationObserver((mutations, obs) => {
            if (document.querySelector('.markdownit li')) {
                obs.disconnect()
                initTracker(userConfig)
            }
        })

        observer.observe(document.body, {
            childList: true,
            subtree: true,
        })
        return
    }

    // Find all h1 date sections within article tree-content
    const dateSections = Array.from(
        document.querySelectorAll('article .tree-content h1'),
    ).filter((el) => {
        const text = el.textContent.trim()
        // Match dates like 2025-03-11 or 2025-01-11~01-12
        return /^\d{4}-\d{2}-\d{2}(~\d{2}-\d{2})?/.test(text)
    })

    // Create and populate activity map
    const activityMap = new Map()

    for (const section of dateSections) {
        // Extract just the date portion (before first space)
        const dateText = section.textContent.trim().split(' ')[0]
        // console.log(`Processing date: ${dateText}`);

        const dates = []
        const [year, month, day] = dateText.split('-')

        // Handle date ranges (e.g., 2024-10-18~10-24)
        if (dateText.includes('~')) {
            const [start, end] = dateText.split('~')
            const [startYear, startMonth, startDay] = start.split('-')

            // Check if end date has year or just month-day
            const endParts = end.split('-')
            const endYear = endParts.length === 3 ? endParts[0] : startYear
            const endMonth = endParts.length === 3 ? endParts[1] : endParts[0]
            const endDay = endParts.length === 3 ? endParts[2] : endParts[1]

            const date = new Date(endYear, endMonth - 1, endDay)
            const dateStr = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`
            dates.push(dateStr)
            // console.log(`  Adding date range end date: ${dateStr}`, {
            //     start,
            //     end,
            //     endYear,
            //     endMonth,
            //     endDay
            // });
        } else {
            // Standardize single date format
            const date = new Date(year, month - 1, day)
            const dateStr = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`
            dates.push(dateStr)
            // console.log(`  Adding single date entry: ${dateStr}`);
        }

        // Count items using same logic as test function
        let count = 0
        const headers = Array.from(
            document.querySelectorAll('article .tree-content h1'),
        )
        const header = headers.find((h) => h.textContent.includes(dateText))

        if (header) {
            const content =
                header.parentElement.querySelector('.markdownit') ||
                header.closest('.tree-content')?.querySelector('.markdownit')

            if (content) {
                const items = content.querySelectorAll('li')
                count = items.length
            }
        }

        // Store activity using strictly padded format (YYYY-MM-DD)
        for (const date of dates) {
            const [year, month, day] = date.split('-')
            const dateKey = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`

            // console.log(`Storing activity for ${dateKey}:`, count);
            activityMap.set(dateKey, count)
        }
    }

    // Make activityMap available globally for debugging
    window.activityMap = activityMap
    // console.log('activityMap available as window.activityMap', activityMap);

    // Generate activity data string for the graph
    const activityData = Array.from(activityMap.entries())
        .flatMap(([date, count]) =>
            Array(Math.max(1, Math.floor(count))).fill(date),
        )
        .join(',')

    // Render the activity graph
    const graphContainer = document.getElementById('learning-activity')
    if (graphContainer) {
        graphContainer.innerHTML = `
            <activity-graph
                activity-data="${activityData}"
                activity-levels="${config.activityLevels.join(',')}"
                first-day-of-week="${config.firstDayOfWeek}"
                style="width:100%"
            ></activity-graph>
        `
    }

    // Test specific date
    // testDateActivity('2025-05-14');
}

// Start the tracker after DOM is ready
document.addEventListener('DOMContentLoaded', () => initTracker())

function renderHabitTracker(activityMap, config = DEFAULT_CONFIG) {
    const now = new Date()
    const currentYear = now.getFullYear()
    const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
    ]

    // Create container for the tracker
    const container = document.createElement('div')
    container.className = 'habit-tracker'
    container.style.fontFamily = 'system-ui, sans-serif'
    container.style.maxWidth = '900px'
    container.style.margin = '2rem auto'

    // Create month labels
    const monthRow = document.createElement('div')
    monthRow.style.display = 'flex'
    monthRow.style.marginBottom = '10px'

    for (const month of months) {
        const monthCell = document.createElement('div')
        monthCell.textContent = month
        monthCell.style.width = 'calc(100% / 12)'
        monthCell.style.textAlign = 'center'
        monthRow.appendChild(monthCell)
    }

    container.appendChild(monthRow)

    // Create grid for each day of the year
    const grid = document.createElement('div')
    grid.style.display = 'flex'
    grid.style.flexWrap = 'wrap'
    grid.style.gap = '3px'

    // Calculate first day of year (0 = Sunday, 1 = Monday, etc.)
    const firstDay = new Date(currentYear, 0, 1).getDay()
    // Add empty cells for days before first day of year
    for (let i = 0; i < firstDay; i++) {
        const emptyCell = document.createElement('div')
        emptyCell.style.width = '15px'
        emptyCell.style.height = '15px'
        grid.appendChild(emptyCell)
    }

    // Create cells for each day of the year, grouped by month
    const currentMonth = 0
    const dayCount = 0
    const monthDayCounts = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if (
        (currentYear % 4 === 0 && currentYear % 100 > 0) ||
        currentYear % 400 === 0
    ) {
        monthDayCounts[1] = 29 // February in leap year
    }

    // Track current position in grid
    let currentDayOfWeek = firstDay

    for (let month = 0; month < 12; month++) {
        const daysInMonth = monthDayCounts[month]

        for (let day = 1; day <= daysInMonth; day++) {
            // Add empty cells at start of month if needed
            if (day === 1 && currentDayOfWeek > 0) {
                for (let i = 0; i < currentDayOfWeek; i++) {
                    const emptyCell = document.createElement('div')
                    emptyCell.style.width = '15px'
                    emptyCell.style.height = '15px'
                    grid.appendChild(emptyCell)
                }
            }

            const dateStr = `${currentYear}-${(month + 1).toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`

            // Use strictly padded format for lookup (YYYY-MM-DD)
            const lookupDate = `${currentYear}-${(month + 1).toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`
            const activity = activityMap.get(lookupDate) || 0
            // Activity lookup remains silent now
            const intensity = Math.min(1, activity / 5) // Normalize to 0-1 scale

            const dayCell = document.createElement('div')
            dayCell.className = 'day-cell'
            dayCell.style.width = '15px'
            dayCell.style.height = '15px'
            dayCell.style.borderRadius = '2px'
            dayCell.style.backgroundColor = getActivityColor(intensity, config)
            dayCell.style.position = 'relative'

            // Tooltip with date and activity info
            dayCell.addEventListener('mouseover', (e) => {
                const tooltip = document.createElement('div')
                tooltip.textContent = `${dateStr}: ${activity} items`
                tooltip.style.position = 'absolute'
                tooltip.style.bottom = '100%'
                tooltip.style.left = '50%'
                tooltip.style.transform = 'translateX(-50%)'
                tooltip.style.backgroundColor = '#333'
                tooltip.style.color = 'white'
                tooltip.style.padding = '4px 8px'
                tooltip.style.borderRadius = '4px'
                tooltip.style.fontSize = '12px'
                tooltip.style.whiteSpace = 'nowrap'
                tooltip.style.zIndex = '100'
                tooltip.style.marginBottom = '5px'

                dayCell.appendChild(tooltip)

                setTimeout(() => {
                    if (dayCell.contains(tooltip)) {
                        dayCell.removeChild(tooltip)
                    }
                }, 2000)
            })

            grid.appendChild(dayCell)

            // Update day of week counter
            currentDayOfWeek = (currentDayOfWeek + 1) % 7
        }
    }

    container.appendChild(grid)

    // Add legend
    const legend = document.createElement('div')
    legend.style.display = 'flex'
    legend.style.justifyContent = 'center'
    legend.style.marginTop = '10px'
    legend.style.gap = '10px'
    legend.style.fontSize = '12px'

    const legendItems = [
        { color: config.colors[0], label: 'No activity' },
        { color: config.colors[1], label: '1 item' },
        { color: config.colors[2], label: '2-3 items' },
        { color: config.colors[3], label: '4-5 items' },
        { color: config.colors[4], label: '5+ items' },
    ]

    for (const item of legendItems) {
        const legendItem = document.createElement('div')
        legendItem.style.display = 'flex'
        legendItem.style.alignItems = 'center'
        legendItem.style.gap = '4px'

        const colorBox = document.createElement('div')
        colorBox.style.width = '12px'
        colorBox.style.height = '12px'
        colorBox.style.backgroundColor = item.color
        colorBox.style.borderRadius = '2px'

        legendItem.appendChild(colorBox)
        legendItem.appendChild(document.createTextNode(item.label))
        legend.appendChild(legendItem)
    }

    container.appendChild(legend)

    // Insert tracker into the dedicated div
    const trackerDiv = document.getElementById('habit-tracker')
    if (trackerDiv) {
        trackerDiv.appendChild(container)
    } // else {
    //     console.warn('Could not find #habit-tracker div');
    // }
}

function testDateActivity(dateStr) {
    console.group('Testing date:', dateStr)
    try {
        // Check if date exists in map
        console.log('Checking activityMap for:', dateStr)
        const count = window.activityMap.get(dateStr)
        console.log('Raw count from map:', count)

        // Check only the fully padded format
        console.log('Checking for fully padded date format:', dateStr)

        // Find corresponding DOM elements
        const headers = Array.from(
            document.querySelectorAll('article .tree-content h1'),
        )
        const header = headers.find((h) => h.textContent.includes(dateStr))
        console.log('Header element:', header) //, 'Matched from:', headers);

        if (header) {
            const content =
                header.parentElement.querySelector('.markdownit') ||
                header.closest('.tree-content')?.querySelector('.markdownit')
            console.log('Content element:', content)

            if (content) {
                const items = content.querySelectorAll('li')
                console.log('List items found:', items.length, items)
            }
        }
    } catch (e) {
        console.error('Test failed:', e)
    }
    console.groupEnd()
}

function getActivityColor(intensity, config = DEFAULT_CONFIG) {
    // GitHub-style color gradient
    if (intensity <= 0) return config.colors[0]
    if (intensity < 0.2) return config.colors[1]
    if (intensity < 0.4) return config.colors[2]
    if (intensity < 0.6) return config.colors[3]
    return config.colors[4]
}
