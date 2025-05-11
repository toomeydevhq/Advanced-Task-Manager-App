document.addEventListener('DOMContentLoaded', function() {
    // DOM Elements
    const themeToggle = document.querySelector('.theme-toggle');
    const darkModeToggle = document.getElementById('dark-mode-toggle');
    const addTaskBtn = document.getElementById('add-task-btn');
    const taskModal = document.getElementById('task-modal');
    const taskForm = document.getElementById('task-form');
    const cancelTaskBtn = document.getElementById('cancel-task');
    const closeModalBtn = document.querySelector('.close-btn');
    const navItems = document.querySelectorAll('.nav-menu li');
    const bottomNavItems = document.querySelectorAll('.bottom-nav-menu li');
    const contentSections = document.querySelectorAll('.content-section');
    const sectionTitle = document.getElementById('section-title');
    const filterBtns = document.querySelectorAll('.filter-btn');
    const sortSelect = document.getElementById('sort-tasks');
    const toast = document.getElementById('toast');

    // State
    let tasks = JSON.parse(localStorage.getItem('tasks')) || [];
    let currentDate = new Date();
    let currentFilter = 'all';
    let currentSort = 'newest';

    // Initialize the app
    init();

    // Event Listeners
    themeToggle.addEventListener('click', toggleTheme);
    darkModeToggle.addEventListener('click', toggleTheme);
    addTaskBtn.addEventListener('click', () => openTaskModal());
    cancelTaskBtn.addEventListener('click', closeTaskModal);
    closeModalBtn.addEventListener('click', closeTaskModal);
    taskModal.addEventListener('click', (e) => {
        if (e.target === taskModal) closeTaskModal();
    });
    taskForm.addEventListener('submit', handleTaskSubmit);
    sortSelect.addEventListener('change', (e) => {
        currentSort = e.target.value;
        renderTasks();
    });

    // Navigation
    navItems.forEach(item => {
        item.addEventListener('click', () => {
            const section = item.getAttribute('data-section');
            showSection(section);
        });
    });

    bottomNavItems.forEach(item => {
        item.addEventListener('click', () => {
            const section = item.getAttribute('data-section');
            showSection(section);
            bottomNavItems.forEach(navItem => navItem.classList.remove('active'));
            item.classList.add('active');
        });
    });

    filterBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            filterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentFilter = btn.getAttribute('data-filter');
            renderTasks();
        });
    });

    // Calendar controls
    initCalendar();
    document.getElementById('prev-month').addEventListener('click', () => {
        currentDate.setMonth(currentDate.getMonth() - 1);
        renderCalendar();
    });
    document.getElementById('next-month').addEventListener('click', () => {
        currentDate.setMonth(currentDate.getMonth() + 1);
        renderCalendar();
    });

    // Functions
    function init() {
        if (localStorage.getItem('darkMode') === 'true') {
            document.body.classList.add('dark-theme');
            darkModeToggle.checked = true;
        }
        
        updateStatistics();
        renderTasks();
        renderCalendar();
        showSection('dashboard');
        setActiveNavItem('dashboard');
        
        // Register Service Worker
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/sw.js')
                    .then(registration => {
                        console.log('ServiceWorker registration successful');
                    })
                    .catch(err => {
                        console.log('ServiceWorker registration failed: ', err);
                    });
            });
        }
    }

    function setActiveNavItem(section) {
        navItems.forEach(item => {
            item.classList.remove('active');
            if (item.getAttribute('data-section') === section) {
                item.classList.add('active');
            }
        });
        
        bottomNavItems.forEach(item => {
            item.classList.remove('active');
            if (item.getAttribute('data-section') === section) {
                item.classList.add('active');
            }
        });
    }

    function toggleTheme() {
        document.body.classList.toggle('dark-theme');
        const isDarkMode = document.body.classList.contains('dark-theme');
        localStorage.setItem('darkMode', isDarkMode);
        darkModeToggle.checked = isDarkMode;
    }

    function showSection(section) {
        contentSections.forEach(sec => sec.classList.remove('active'));
        document.getElementById(`${section}-section`).classList.add('active');
        sectionTitle.textContent = section.charAt(0).toUpperCase() + section.slice(1);
        setActiveNavItem(section);
        
        if (section === 'stats') {
            updateStatistics();
        } else if (section === 'tasks') {
            renderTasks();
        } else if (section === 'calendar') {
            renderCalendar();
        }
    }

    function openTaskModal(task = null) {
        const modalTitle = document.getElementById('modal-title');
        const taskId = document.getElementById('task-id');
        const taskTitle = document.getElementById('task-title');
        const taskDescription = document.getElementById('task-description');
        const taskCategory = document.getElementById('task-category');
        const taskDueDate = document.getElementById('task-due-date');
        const taskPriority = document.getElementById('task-priority');
        const taskReminder = document.getElementById('task-reminder');

        if (task) {
            modalTitle.textContent = 'Edit Task';
            taskId.value = task.id;
            taskTitle.value = task.title;
            taskDescription.value = task.description || '';
            taskCategory.value = task.category || 'personal';
            taskDueDate.value = task.dueDate || '';
            taskPriority.value = task.priority || 'medium';
            taskReminder.value = task.reminder || 'none';
        } else {
            modalTitle.textContent = 'Add New Task';
            taskId.value = '';
            taskForm.reset();
        }

        taskModal.classList.add('active');
    }

    function closeTaskModal() {
        taskModal.classList.remove('active');
    }

    function handleTaskSubmit(e) {
        e.preventDefault();
        
        const taskId = document.getElementById('task-id').value;
        const taskTitle = document.getElementById('task-title').value;
        const taskDescription = document.getElementById('task-description').value;
        const taskCategory = document.getElementById('task-category').value;
        const taskDueDate = document.getElementById('task-due-date').value;
        const taskPriority = document.getElementById('task-priority').value;
        const taskReminder = document.getElementById('task-reminder').value;

        const taskData = {
            id: taskId || Date.now().toString(),
            title: taskTitle,
            description: taskDescription,
            category: taskCategory,
            dueDate: taskDueDate,
            priority: taskPriority,
            reminder: taskReminder,
            completed: false,
            createdAt: new Date().toISOString()
        };

        if (taskId) {
            const index = tasks.findIndex(t => t.id === taskId);
            if (index !== -1) {
                tasks[index] = taskData;
                showToast('Task updated successfully');
            }
        } else {
            tasks.unshift(taskData);
            showToast('Task added successfully');
        }

        saveTasks();
        closeTaskModal();
        renderTasks();
        updateStatistics();
        renderCalendar();
    }

    function saveTasks() {
        localStorage.setItem('tasks', JSON.stringify(tasks));
    }

    function renderTasks() {
        const tasksContainer = document.getElementById('tasks-container');
        const recentTasksList = document.getElementById('recent-tasks-list');
        
        let filteredTasks = [...tasks];
        
        switch (currentFilter) {
            case 'today':
                const today = new Date().toISOString().split('T')[0];
                filteredTasks = filteredTasks.filter(task => task.dueDate === today);
                break;
            case 'completed':
                filteredTasks = filteredTasks.filter(task => task.completed);
                break;
            case 'overdue':
                filteredTasks = filteredTasks.filter(task => 
                    !task.completed && task.dueDate && new Date(task.dueDate) < new Date()
                );
                break;
        }
        
        switch (currentSort) {
            case 'newest':
                filteredTasks.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
                break;
            case 'oldest':
                filteredTasks.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
                break;
            case 'due-date':
                filteredTasks.sort((a, b) => {
                    if (!a.dueDate && !b.dueDate) return 0;
                    if (!a.dueDate) return 1;
                    if (!b.dueDate) return -1;
                    return new Date(a.dueDate) - new Date(b.dueDate);
                });
                break;
            case 'priority':
                const priorityOrder = { high: 1, medium: 2, low: 3 };
                filteredTasks.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
                break;
        }
        
        tasksContainer.innerHTML = filteredTasks.length > 0 ? 
            filteredTasks.map(task => createTaskCard(task)).join('') :
            `<div class="empty-state">
                <span class="material-icons-round">assignment</span>
                <p>No tasks found</p>
            </div>`;
            
        const recentTasks = [...tasks]
            .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
            .slice(0, 5);
            
        recentTasksList.innerHTML = recentTasks.map(task => createTaskCard(task, true)).join('');
        
        document.querySelectorAll('.task-edit').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const taskId = e.currentTarget.closest('.task-card').dataset.id;
                const task = tasks.find(t => t.id === taskId);
                openTaskModal(task);
            });
        });
        
        document.querySelectorAll('.task-delete').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const taskId = e.currentTarget.closest('.task-card').dataset.id;
                deleteTask(taskId);
            });
        });
        
        document.querySelectorAll('.task-toggle').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const taskId = e.currentTarget.closest('.task-card').dataset.id;
                toggleTaskComplete(taskId);
            });
        });
    }

    function createTaskCard(task, isCompact = false) {
        const dueDate = task.dueDate ? new Date(task.dueDate) : null;
        const isOverdue = dueDate && dueDate < new Date() && !task.completed;
        const formattedDate = dueDate ? dueDate.toLocaleDateString('en-US', { 
            month: 'short', day: 'numeric', year: 'numeric' 
        }) : 'No due date';
        
        return `
            <div class="task-card ${task.priority}-priority ${task.completed ? 'completed' : ''}" data-id="${task.id}">
                <div class="task-header">
                    <h3 class="task-title">${task.title}</h3>
                    <span class="task-category">${task.category}</span>
                </div>
                ${!isCompact && task.description ? `<p class="task-description">${task.description}</p>` : ''}
                <div class="task-footer">
                    <div class="task-due-date ${isOverdue ? 'overdue' : ''}">
                        <span class="material-icons-round">event</span>
                        <span>${formattedDate}</span>
                    </div>
                    <div class="task-actions">
                        <button class="task-toggle" title="${task.completed ? 'Mark incomplete' : 'Mark complete'}">
                            <span class="material-icons-round">${task.completed ? 'check_circle' : 'radio_button_unchecked'}</span>
                        </button>
                        <button class="task-edit" title="Edit">
                            <span class="material-icons-round">edit</span>
                        </button>
                        <button class="task-delete" title="Delete">
                            <span class="material-icons-round">delete</span>
                        </button>
                    </div>
                </div>
            </div>
        `;
    }

    function deleteTask(taskId) {
        if (confirm('Are you sure you want to delete this task?')) {
            tasks = tasks.filter(task => task.id !== taskId);
            saveTasks();
            renderTasks();
            updateStatistics();
            renderCalendar();
            showToast('Task deleted successfully');
        }
    }

    function toggleTaskComplete(taskId) {
        const task = tasks.find(t => t.id === taskId);
        if (task) {
            task.completed = !task.completed;
            saveTasks();
            renderTasks();
            updateStatistics();
            showToast(`Task marked as ${task.completed ? 'complete' : 'incomplete'}`);
        }
    }

    function updateStatistics() {
        const totalTasks = tasks.length;
        const completedTasks = tasks.filter(task => task.completed).length;
        const overdueTasks = tasks.filter(task => 
            !task.completed && task.dueDate && new Date(task.dueDate) < new Date()
        ).length;
        const pendingCount = tasks.filter(task => 
            !task.completed && task.dueDate && new Date(task.dueDate).toDateString() === new Date().toDateString()
        ).length;

        document.getElementById('total-tasks').textContent = totalTasks;
        document.getElementById('completed-tasks').textContent = completedTasks;
        document.getElementById('overdue-tasks').textContent = overdueTasks;
        document.getElementById('pending-count').textContent = pendingCount;

        const hour = new Date().getHours();
        let timeOfDay = 'Morning';
        if (hour >= 12 && hour < 17) timeOfDay = 'Afternoon';
        else if (hour >= 17) timeOfDay = 'Evening';
        document.getElementById('time-of-day').textContent = timeOfDay;

        updateCompletionChart(completedTasks, totalTasks - completedTasks);
        updateCategoryChart();
        updatePriorityChart();
        updateProductivityChart();
    }

    function updateCompletionChart(completed, pending) {
        const ctx = document.getElementById('completion-canvas').getContext('2d');
        
        if (window.completionChart) {
            window.completionChart.destroy();
        }
        
        window.completionChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Completed', 'Pending'],
                datasets: [{
                    data: [completed, pending],
                    backgroundColor: [
                        '#10b981',
                        '#6366f1'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }

    function updateCategoryChart() {
        const categories = {};
        tasks.forEach(task => {
            categories[task.category] = (categories[task.category] || 0) + 1;
        });
        
        const ctx = document.getElementById('category-canvas').getContext('2d');
        const categoryColors = {
            work: '#3b82f6',
            personal: '#ec4899',
            shopping: '#f59e0b',
            other: '#10b981'
        };
        
        if (window.categoryChart) {
            window.categoryChart.destroy();
        }
        
        window.categoryChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: Object.keys(categories),
                datasets: [{
                    data: Object.values(categories),
                    backgroundColor: Object.keys(categories).map(cat => categoryColors[cat] || '#6b7280'),
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    function updatePriorityChart() {
        const priorities = { high: 0, medium: 0, low: 0 };
        tasks.forEach(task => {
            priorities[task.priority]++;
        });
        
        const ctx = document.getElementById('priority-canvas').getContext('2d');
        
        if (window.priorityChart) {
            window.priorityChart.destroy();
        }
        
        window.priorityChart = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: ['High', 'Medium', 'Low'],
                datasets: [{
                    data: [priorities.high, priorities.medium, priorities.low],
                    backgroundColor: [
                        '#ef4444',
                        '#f59e0b',
                        '#10b981'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }

    function updateProductivityChart() {
        const last7Days = [...Array(7)].map((_, i) => {
            const date = new Date();
            date.setDate(date.getDate() - i);
            return date.toISOString().split('T')[0];
        }).reverse();

        const productivityData = last7Days.map(date => {
            const dayTasks = tasks.filter(task => 
                task.createdAt && task.createdAt.split('T')[0] === date
            );
            const completed = dayTasks.filter(task => task.completed).length;
            return {
                date,
                total: dayTasks.length,
                completed,
                productivity: dayTasks.length ? (completed / dayTasks.length) * 100 : 0
            };
        });

        const ctx = document.getElementById('productivity-canvas').getContext('2d');
        
        if (window.productivityChart) {
            window.productivityChart.destroy();
        }
        
        window.productivityChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: last7Days.map(d => new Date(d).toLocaleDateString('en-US', { weekday: 'short' })),
                datasets: [{
                    label: 'Productivity %',
                    data: productivityData.map(d => d.productivity),
                    borderColor: '#6366f1',
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    tension: 0.3,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    }

    function initCalendar() {
        renderCalendar();
    }

    function renderCalendar() {
        const calendarGrid = document.getElementById('calendar-grid');
        const calendarEvents = document.getElementById('calendar-events');
        const monthYear = document.getElementById('current-month');
        
        const year = currentDate.getFullYear();
        const month = currentDate.getMonth();
        
        monthYear.textContent = `${new Date(year, month).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}`;
        
        const firstDay = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        
        calendarGrid.innerHTML = '';
        calendarEvents.innerHTML = '';
        
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        days.forEach(day => {
            const dayHeader = document.createElement('div');
            dayHeader.className = 'calendar-day-header';
            dayHeader.textContent = day;
            calendarGrid.appendChild(dayHeader);
        });
        
        for (let i = 0; i < firstDay; i++) {
            const emptyDay = document.createElement('div');
            emptyDay.className = 'calendar-day empty';
            calendarGrid.appendChild(emptyDay);
        }
        
        for (let day = 1; day <= daysInMonth; day++) {
            const date = new Date(year, month, day);
            const dateString = date.toISOString().split('T')[0];
            const dayElement = document.createElement('div');
            dayElement.className = 'calendar-day';
            
            const dayTasks = tasks.filter(task => task.dueDate === dateString);
            
            // Highlight today's date
            if (date.toDateString() === new Date().toDateString()) {
                dayElement.classList.add('today');
                dayElement.innerHTML = `
                    <div class="calendar-day-number">${day}</div>
                    ${dayTasks.slice(0, 2).map(task => `
                        <div class="calendar-event ${task.priority}-priority">
                            ${task.title}
                        </div>
                    `).join('')}
                    ${dayTasks.length > 2 ? `<div class="calendar-event more">+${dayTasks.length - 2} more</div>` : ''}
                `;
            } else {
                dayElement.innerHTML = `
                    <div class="calendar-day-number">${day}</div>
                    ${dayTasks.slice(0, 2).map(task => `
                        <div class="calendar-event ${task.priority}-priority">
                            ${task.title}
                        </div>
                    `).join('')}
                    ${dayTasks.length > 2 ? `<div class="calendar-event more">+${dayTasks.length - 2} more</div>` : ''}
                `;
            }
            
            dayElement.addEventListener('click', () => {
                openTaskModal();
                document.getElementById('task-due-date').value = dateString;
                
                calendarEvents.innerHTML = `
                    <h4>Tasks for ${date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}</h4>
                    ${dayTasks.length > 0 ? 
                        dayTasks.map(task => createTaskCard(task)).join('') :
                        `<p>No tasks for this day</p>`
                    }
                `;
            });
            
            calendarGrid.appendChild(dayElement);
        }
    }

    function showToast(message, type = 'success') {
        toast.textContent = message;
        toast.className = `toast ${type}`;
        toast.classList.add('active');
        
        setTimeout(() => {
            toast.classList.remove('active');
        }, 3000);
    }
});
