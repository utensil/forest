import '@mariohamann/activity-graph'

interface ActivityConfig {
    activityLevels: number[]
    colors?: string[]
    dateFormat?: string
    firstDayOfWeek?: number
    maxItems?: number
}

const DEFAULT_CONFIG: ActivityConfig = {
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
function initTracker(userConfig: Partial<ActivityConfig> = {}): void {
    const config: ActivityConfig = { ...DEFAULT_CONFIG, ...userConfig }
    // Ensure activity-graph component is defined
    if (!customElements.get('activity-graph')) {
        console.error('activity-graph component not registered')
        return
    }

    // Wait for markdown content using MutationObserver
    if (document.querySelector('.markdownit.grace-loading')) {
        const observer = new MutationObserver((mutations, obs) => {
            if (!document.querySelector('.markdownit.grace-loading')) {
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
        document.querySelectorAll('article section details summary header h1'),
    ).filter((el) => {
        const text = el.textContent.trim()
        // Match dates like 2025-03-11 or 2025-01-11~01-12
        return /^\d{4}-\d{2}-\d{2}(~\d{2}-\d{2})?/.test(text)
    })

    // Create and populate activity map
    const activityMap = new Map<string, number>()

    for (const section of dateSections) {
        // Extract just the date portion (before first space or :)
        const dateText = section.textContent.trim().split(/[ :]/)[0]
        // console.log(`Processing date: ${dateText}`);

        const dates: string[] = []
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
            document.querySelectorAll('article section details summary header h1'),
        )
        const header = headers.find((h) => h.textContent.includes(dateText))

        if (header) {
            const parent = header.parentElement
            let content: Element | null = null
            if (parent) {
                content = parent.querySelector('.markdownit')
                if (!content) {
                    const closest = parent.closest('section')
                    content = closest
                        ? closest.querySelector('.markdownit')
                        : null
                }
            }
            if (content) {
                const items = content.querySelectorAll(':scope > ul > li')
                count = items.length
                // console.log(`${dateText}: ${count}, ${content.innerHTML.trim()}`);
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
    // window.activityMap = activityMap
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
}

// Start the tracker after DOM is ready
document.addEventListener('DOMContentLoaded', () => initTracker())
