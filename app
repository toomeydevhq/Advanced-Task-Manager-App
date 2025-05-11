// DOM Elements
const sideNavItems = document.querySelectorAll('.nav-menu li');
const contentSections = document.querySelectorAll('.content-section');
const sectionTitle = document.getElementById('section-title');
const addTaskBtn = document.getElementById('add-task-btn');
const taskModal = document.getElementById('task-modal');
const taskForm = document.getElementById('task-form');
const cancelTaskBtn = document.getElementById('cancel-task');
const closeBtn = document.querySelector('.close-btn');
const toast = document.getElementById('toast');
const themeToggle = document.querySelector('.theme-toggle');
const darkModeToggle = document.getElementById('dark-mode-toggle');
const mobileMenuBtn = document.getElementById('hamburger-menu');

// Stats elements
const totalTasksEl = document.getElementById('total-tasks');
const completedTasksEl = document.getElementById('completed-tasks');
const pendingTasksEl = document.getElementById('pending-tasks');
const overdueTasksEl = document.getElementById('overdue-tasks');

// Calendar elements
const prevMonthBtn = document.getElementById('prev-month');
const nextMonthBtn = document.getElementById('next-month');
const currentMonthEl = document.getElementById('current-month');
const calendarGrid = document.getElementById('calendar-grid');
const calendarEvents = document.getElementById('calendar-events');

// Task data
let tasks = JSON.parse(localStorage.getItem('tasks')) || [];
let currentFilter = 'all';
let currentDate = new Date();

// Initialize the app
function init() {
    console.log('App initialized', { tasks, totalTasksEl, mobileMenuBtn });
    setupEventListeners();
    loadSettings();
    updateTimeOfDay();
    renderTasks();
    updateStats();
    renderRecentTasks();
    renderCalendar();
    registerServiceWorker();
}

// Set up event listeners
function setupEventListeners() {
    console.log('Setting up event listeners');
    
    // Navigation
    sideNavItems.forEach(item => {
        item.addEventListener('click', () => {
            console.log('Nav item clicked:', item.dataset.section);
            switchSection(item.dataset.section);
        });
    });
    
    // Mobile menu toggle
    if (mobileMenuBtn) {
        console.log('Mobile menu button found');
        mobileMenuBtn.addEventListener('click', () => {
            console.log('Hamburger menu clicked');
            toggleMobileMenu();
        });
    } else {
        console.error('Mobile menu button not found');
    }
    
    // Task modal
    if (addTaskBtn) {
        addTaskBtn.addEventListener('click', () => openTaskModal());
    } else {
        console.error('Add task button not found');
    }
    if (taskForm) {
        taskForm.addEventListener('submit', handleTaskSubmit);
    }
    if (cancelTaskBtn) {
        cancelTaskBtn.addEventListener('click', closeTaskModal);
    }
    if (closeBtn) {
        closeBtn.addEventListener('click', closeTaskModal);
    }
    
    // Task filtering
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            console.log('Filter button clicked:', btn.dataset.filter);
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentFilter = btn.dataset.filter;
            renderTasks();
        });
    });
    
    // Theme toggle
    if (themeToggle) themeToggle.addEventListener('click', toggleTheme);
    if (darkModeToggle) darkModeToggle.addEventListener('change', toggleTheme);
    
    // Calendar navigation
    if (prevMonthBtn) prevMonthBtn.addEventListener('click', () => {
        currentDate.setMonth(currentDate.getMonth() - 1);
        renderCalendar();
    });
    if (nextMonthBtn) nextMonthBtn.addEventListener('click', () => {
        currentDate.setMonth(currentDate.getMonth() + 1);
        renderCalendar();
    });
    
    // Click outside modal to close
    window.addEventListener('click', (e) => {
        if (e.target === taskModal) {
            closeTaskModal();
        }
    });
}

// Mobile Menu Toggle
function toggleMobileMenu() {
    const sideNav = document.querySelector('.side-nav');
    if (sideNav) {
        sideNav.classList.toggle('mobile-visible');
        document.body.classList.toggle('no-scroll');
        console.log('Toggled mobile menu', { mobileVisible: sideNav.classList.contains('mobile-visible') });
    } else {
        console.error('Side nav not found');
    }
}

// Navigation Functions
function switchSection(section) {
    sideNavItems.forEach(item => {
        item.classList.remove('active');
        if (item.dataset.section === section) {
            item.classList.add('active');
        }
    });
    
    contentSections.forEach(sec => {
        sec.classList.remove('active');
        if (sec.id === `${section}-section`) {
            sec.classList.add('active');
        }
    });
    
    const activeItem = document.querySelector(`.nav-menu li[data-section="${section}"]`);
    if (activeItem && sectionTitle) {
        sectionTitle.textContent = activeItem.querySelector('span:last-child').textContent;
    }
    
    const sideNav = document.querySelector('.side-nav');
    if (sideNav && sideNav.classList.contains('mobile-visible')) {
        toggleMobileMenu();
    }
}

// Task Modal Functions
function openTaskModal(task = null) {
    const modalTitle = document.getElementById('modal-title');
    const taskId = document.getElementById('task-id');
    const taskTitle = document.getElementById('task-title');
    const taskDescription = document.getElementById('task-description');
    const taskPriority = document.getElementById('task-priority');
    const taskDueDate = document.getElementById('task-due-date');
    
    if (task) {
        modalTitle.textContent = 'Edit Task';
        taskId.value = task.id;
        taskTitle.value = task.title;
        taskDescription.value = task.description || '';
        taskPriority.value = task.priority || 'medium';
        taskDueDate.value = task.dueDate || '';
    } else {
        modalTitle.textContent = 'Add New Task';
        taskForm.reset();
        taskId.value = '';
        taskDueDate.value = '';
        const defaultPriority = document.getElementById('default-priority');
        if (defaultPriority) {
            taskPriority.value = defaultPriority.value;
        }
    }
    
    if (taskModal) {
        taskModal.classList.add('active');
        document.body.classList.add('no-scroll');
    }
}

// Task CRUD Operations
function handleTaskSubmit(e) {
    e.preventDefault();
    
    const taskId = document.getElementById('task-id').value;
    const taskTitle = document.getElementById('task-title').value;
    const taskDescription = document.getElementById('task-description').value;
    const taskPriority = document.getElementById('task-priority').value;
    const taskDueDate = document.getElementById('task-due-date').value;
    
    const taskData = {
        title: taskTitle,
        description: taskDescription,
        priority: taskPriority,
        dueDate: taskDueDate,
        completed: false,
        createdAt: new Date().toISOString()
    };
    
    if (taskId) {
        const existingTaskIndex = tasks.findIndex(task => task.id === taskId);
        if (existingTaskIndex !== -1) {
            taskData.id = taskId;
            taskData.completed = tasks[existingTaskIndex].completed;
            tasks[existingTaskIndex] = taskData;
            showToast('Task updated successfully');
        }
    } else {
        taskData.id = Date.now().toString();
        tasks.unshift(taskData);
        showToast('Task added successfully');
        
        if (taskDueDate) {
            scheduleNotification(taskData);
        }
    }
    
    console.log('Task submitted:', taskData, tasks);
    saveTasks();
    renderTasks();
    updateStats();
    renderRecentTasks();
    renderCalendar();
    closeTaskModal();
}

function deleteTask(taskId) {
    tasks = tasks.filter(task => task.id !== taskId);
    saveTasks();
    renderTasks();
    renderRecentTasks();
    updateStats();
    renderCalendar();
    showToast('Task deleted');
}

function toggleTaskCompletion(taskId) {
    const task = tasks.find(task => task.id === taskId);
    if (task) {
        task.completed = !task.completed;
        saveTasks();
        renderTasks();
        renderRecentTasks();
        updateStats();
        renderCalendar();
        showToast(`Task marked as ${task.completed ? 'completed' : 'pending'}`);
    }
}

function saveTasks() {
    localStorage.setItem('tasks', JSON.stringify(tasks));
    console.log('Tasks saved to localStorage:', tasks);
}

// Task Rendering Functions
function renderTasks() {
    const tasksContainer = document.getElementById('tasks-container');
    if (!tasksContainer) {
        console.error('Tasks container not found');
        return;
    }
    
    tasksContainer.innerHTML = '';
    
    let filteredTasks = getFilteredTasks();
    
    if (filteredTasks.length === 0) {
        tasksContainer.innerHTML = `
            <div class="empty-state">
                <span class="material-icons-round">assignment</span>
                <p>No tasks found</p>
            </div>
        `;
        return;
    }
    
    filteredTasks.forEach(task => {
        const taskElement = document.createElement('div');
        taskElement.className = `task-card ${task.completed ? 'completed' : ''} ${task.priority}-priority`;
        
        const dueDate = task.dueDate ? new Date(task.dueDate) : null;
        const isOverdue = dueDate && !task.completed && dueDate < new Date();
        
        taskElement.innerHTML = `
            <div class="task-header">
                <span class="task-title">${task.title}</span>
                <span class="task-priority">${task.priority}</span>
            </div>
            ${task.description ? `<p class="task-description">${task.description}</p>` : ''}
            <div class="task-footer">
                <span class="task-due-date ${isOverdue ? 'overdue' : ''}">
                    <span class="material-icons-round">schedule</span>
                    ${dueDate ? dueDate.toLocaleDateString() : 'No due date'}
                </span>
                <div class="task-actions">
                    <button class="complete-btn" data-id="${task.id}">
                        <span class="material-icons-round">${task.completed ? 'undo' : 'check'}</span>
                    </button>
                    <button class="edit-btn" data-id="${task.id}">
                        <span class="material-icons-round">edit</span>
                    </button>
                    <button class="delete-btn" data-id="${task.id}">
                        <span class="material-icons-round">delete</span>
                    </button>
                </div>
            </div>
        `;
        
        tasksContainer.appendChild(taskElement);
    });
    
    document.querySelectorAll('.complete-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            toggleTaskCompletion(e.currentTarget.dataset.id);
        });
    });
    
    document.querySelectorAll('.edit-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const task = tasks.find(task => task.id === e.currentTarget.dataset.id);
            if (task) openTaskModal(task);
        });
    });
    
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            if (confirm('Are you sure you want to delete this task?')) {
                deleteTask(e.currentTarget.dataset.id);
            }
        });
    });
}

function renderRecentTasks() {
    const recentTasksList = document.getElementById('recent-tasks-list');
    if (!recentTasksList) return;
    
    recentTasksList.innerHTML = '';
    
    const recentTasks = [...tasks]
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
        .slice(0, 3);
    
    if (recentTasks.length === 0) {
        recentTasksList.innerHTML = '<p>No recent tasks</p>';
        return;
    }
    
    recentTasks.forEach(task => {
        const taskElement = document.createElement('div');
        taskElement.className = `task-card ${task.completed ? 'completed' : ''} ${task.priority}-priority`;
        
        taskElement.innerHTML = `
            <div class="task-header">
                <span class="task-title">${task.title}</span>
                <span class="task-priority">${task.priority}</span>
            </div>
            <div class="task-footer">
                <button class="complete-btn" data-id="${task.id}">
                    <span class="material-icons-round">${task.completed ? 'undo' : 'check'}</span>
                </button>
            </div>
        `;
        
        recentTasksList.appendChild(taskElement);
    });
    
    document.querySelectorAll('.complete-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            toggleTaskCompletion(e.currentTarget.dataset.id);
        });
    });
}

// Task Filtering
function getFilteredTasks() {
    let filteredTasks = [...tasks];
    
    if (currentFilter === 'today') {
        const today = new Date();
        filteredTasks = filteredTasks.filter(task => {
            if (!task.dueDate) return false;
            const taskDate = new Date(task.dueDate);
            return taskDate.toDateString() === today.toDateString();
        });
    } else if (currentFilter === 'completed') {
        filteredTasks = filteredTasks.filter(task => task.completed);
    } else if (currentFilter === 'overdue') {
        filteredTasks = filteredTasks.filter(task => {
            if (task.completed || !task.dueDate) return false;
            return new Date(task.dueDate) < new Date();
        });
    }
    
    return filteredTasks;
}

// Stats Functions
function updateStats() {
    const total = tasks.length;
    const completed = tasks.filter(task => task.completed).length;
    const overdue = tasks.filter(task => {
        if (task.completed || !task.dueDate) return false;
        return new Date(task.dueDate) < new Date();
    }).length;
    const pending = total - completed;
    
    console.log('Updating stats:', { total, completed, overdue, pending, tasks });
    
    // Update dashboard stats with existence checks
    if (totalTasksEl) {
        totalTasksEl.textContent = total;
        console.log('Updated totalTasksEl:', total);
    } else {
        console.error('totalTasksEl not found');
    }
    if (completedTasksEl) {
        completedTasksEl.textContent = completed;
        console.log('Updated completedTasksEl:', completed);
    } else {
        console.error('completedTasksEl not found');
    }
    if (overdueTasksEl) {
        overdueTasksEl.textContent = overdue;
        console.log('Updated overdueTasksEl:', overdue);
    } else {
        console.error('overdueTasksEl not found');
    }
    if (pendingTasksEl) {
        pendingTasksEl.textContent = pending;
        console.log('Updated pendingTasksEl:', pending);
    } else {
        console.error('pendingTasksEl not found');
    }
    
    const pendingCountEl = document.getElementById('pending-count');
    if (pendingCountEl) {
        pendingCountEl.textContent = pending;
        console.log('Updated pendingCountEl:', pending);
    } else {
        console.error('pendingCountEl not found');
    }
    
    // Retry if elements not found (possible DOM timing issue)
    if (!totalTasksEl || !completedTasksEl || !overdueTasksEl || !pendingTasksEl || !pendingCountEl) {
        console.warn('Retrying stats update in 100ms');
        setTimeout(updateStats, 100);
    }
}

// Calendar Functions
function renderCalendar() {
    if (!calendarGrid || !currentMonthEl) return;
    
    calendarGrid.innerHTML = '';
    if (calendarEvents) calendarEvents.innerHTML = '';
    
    currentMonthEl.textContent = currentDate.toLocaleDateString('default', { 
        month: 'long', 
        year: 'numeric' 
    });
    
    const firstDay = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    const lastDay = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startingDay = firstDay.getDay();
    
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    days.forEach(day => {
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day-header';
        dayElement.textContent = day;
        calendarGrid.appendChild(dayElement);
    });
    
    for (let i = 0; i < startingDay; i++) {
        const emptyElement = document.createElement('div');
        emptyElement.className = 'calendar-day empty';
        calendarGrid.appendChild(emptyElement);
    }
    
    for (let i = 1; i <= daysInMonth; i++) {
        const dayElement = document.createElement('div');
        dayElement.className = 'calendar-day';
        
        const dayDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), i);
        
        dayElement.innerHTML = `<div class="calendar-day-number">${i}</div>`;
        
        const dayTasks = tasks.filter(task => {
            if (!task.dueDate) return false;
            const taskDate = new Date(task.dueDate);
            return taskDate.toDateString() === dayDate.toDateString();
        });
        
        dayTasks.forEach(task => {
            const taskElement = document.createElement('div');
            taskElement.className = 'calendar-event';
            taskElement.textContent = task.title;
            dayElement.appendChild(taskElement);
        });
        
        const today = new Date();
        if (
            dayDate.getDate() === today.getDate() && 
            dayDate.getMonth() === today.getMonth() && 
            dayDate.getFullYear() === today.getFullYear()
        ) {
            dayElement.style.border = '2px solid var(--primary-color)';
        }
        
        calendarGrid.appendChild(dayElement);
    }
    
    if (calendarEvents) {
        const todayTasks = tasks.filter(task => {
            if (!task.dueDate) return false;
            const taskDate = new Date(task.dueDate);
            const today = new Date();
            return (
                taskDate.getDate() === today.getDate() && 
                taskDate.getMonth() === today.getMonth() && 
                taskDate.getFullYear() === today.getFullYear()
            );
        });
        
        if (todayTasks.length > 0) {
            todayTasks.forEach(task => {
                const eventElement = document.createElement('div');
                eventElement.className = 'task-card';
                eventElement.innerHTML = `
                    <div class="task-header">
                        <span class="task-title">${task.title}</span>
                        <span class="task-priority">${task.priority}</span>
                    </div>
                    <div class="task-footer">
                        <button class="complete-btn" data-id="${task.id}">
                            <span class="material-icons-round">${task.completed ? 'undo' : 'check'}</span>
                        </button>
                    </div>
                `;
                calendarEvents.appendChild(eventElement);
            });
            
            document.querySelectorAll('.complete-btn').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    toggleTaskCompletion(e.currentTarget.dataset.id);
                });
            });
        } else {
            calendarEvents.innerHTML = '<p>No events for today</p>';
        }
    }
}

// Notification Functions
function scheduleNotification(task) {
    if (!('Notification' in window)) {
        console.log('This browser does not support notifications');
        return;
    }
    
    if (!task.dueDate) return;
    
    const dueDate = new Date(task.dueDate);
    const now = new Date();
    const timeUntilDue = dueDate.getTime() - now.getTime();
    
    if (timeUntilDue > 0) {
        if (Notification.permission !== 'granted') {
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    createNotification(task, dueDate);
                }
            });
        } else {
            createNotification(task, dueDate);
        }
    }
}

function createNotification(task, dueDate) {
    const now = new Date();
    const timeUntilDue = dueDate.getTime() - now.getTime();
    
    const notificationTime = timeUntilDue - (60 * 60 * 1000);
    
    if (notificationTime > 0) {
        setTimeout(() => {
            new Notification(`Task Due Soon: ${task.title}`, {
                body: `Due at ${dueDate.toLocaleTimeString()}`,
                icon: 'icons/icon-192x192.png'
            });
        }, notificationTime);
    }
}

// Settings Functions
function loadSettings() {
    const settings = JSON.parse(localStorage.getItem('settings')) || {};
    
    if (settings.darkMode) {
        document.body.classList.add('dark-theme');
        if (darkModeToggle) {
            darkModeToggle.checked = true;
        }
    }
}

function saveSettings() {
    const settings = {
        darkMode: document.body.classList.contains('dark-theme')
    };
    
    localStorage.setItem('settings', JSON.stringify(settings));
}

function toggleTheme() {
    document.body.classList.toggle('dark-theme');
    saveSettings();
}

// Utility Functions
function updateTimeOfDay() {
    const timeOfDayEl = document.getElementById('time-of-day');
    if (!timeOfDayEl) return;
    
    const hour = new Date().getHours();
    let timeOfDay = 'Day';
    
    if (hour < 12) timeOfDay = 'Morning';
    else if (hour < 18) timeOfDay = 'Afternoon';
    else timeOfDay = 'Evening';
    
    timeOfDayEl.textContent = timeOfDay;
}

function showToast(message, type = 'success') {
    if (!toast) return;
    
    toast.textContent = message;
    toast.className = 'toast active';
    
    if (type === 'error') {
        toast.style.backgroundColor = '#ef4444';
    } else {
        toast.style.backgroundColor = '#4f46e5';
    }
    
    setTimeout(() => {
        toast.classList.remove('active');
    }, 3000);
}

// Service Worker Registration
function registerServiceWorker() {
    if ('serviceWorker' in navigator) {
        window.addEventListener('load', () => {
            navigator.serviceWorker.register('/sw.js').then(registration => {
                console.log('ServiceWorker registered');
            }).catch(err => {
                console.log('ServiceWorker registration failed: ', err);
            });
        });
    }
}

// Initialize the app
document.addEventListener('DOMContentLoaded', init);
