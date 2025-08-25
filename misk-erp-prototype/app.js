// MISK EWT ERP Prototype App JavaScript

class MiskERPApp {
    constructor() {
        this.currentScreen = 'landing';
        this.currentCategory = null;
        this.currentScreenName = null;
        this.modalOpen = false;
        
        // Application data
        this.data = {
            categories: [
                {
                    id: "auth",
                    name: "Authentication",
                    icon: "🔐",
                    screens: ["Login", "Forgot Password", "App Lock"],
                    description: "User authentication and security screens"
                },
                {
                    id: "dashboard", 
                    name: "Dashboard",
                    icon: "📊",
                    screens: ["Main Dashboard", "Navigation Drawer"],
                    description: "Main dashboard and navigation components"
                },
                {
                    id: "users",
                    name: "User Management", 
                    icon: "👥",
                    screens: ["Users List", "User Form"],
                    description: "Manage users, roles and permissions"
                },
                {
                    id: "roles",
                    name: "Roles & Permissions",
                    icon: "🛡️", 
                    screens: ["Roles List", "Role Form"],
                    description: "Configure user roles and access permissions"
                },
                {
                    id: "initiatives",
                    name: "Initiatives",
                    icon: "🎯",
                    screens: ["Initiatives List", "Initiative Detail", "Initiative Form"],
                    description: "Track and manage fundraising initiatives"
                },
                {
                    id: "campaigns", 
                    name: "Campaigns",
                    icon: "📢",
                    screens: ["Campaigns List", "Campaign Form"],
                    description: "Create and manage marketing campaigns"
                },
                {
                    id: "tasks",
                    name: "Tasks",
                    icon: "✅", 
                    screens: ["Tasks List", "Task Form"],
                    description: "Assign and track project tasks"
                },
                {
                    id: "donations",
                    name: "Donations",
                    icon: "💰",
                    screens: ["Donations Entry", "Donations List"],
                    description: "Process and track donation records"
                },
                {
                    id: "events",
                    name: "Events & Announcements", 
                    icon: "📅",
                    screens: ["Events List", "Event Form"],
                    description: "Organize events and send announcements"
                },
                {
                    id: "settings",
                    name: "Settings",
                    icon: "⚙️",
                    screens: ["Global Settings", "Payment Settings", "Security Settings"],
                    description: "Configure application and system settings"
                }
            ],
            sampleData: {
                users: [
                    {
                        name: "Muhammad Tanveerullah",
                        email: "muhammad.tanveerullah@gmail.com",
                        designation: "Project Manager",
                        status: "Active",
                        joined: "2025-08-19",
                        avatar: "MT"
                    },
                    {
                        name: "Super Admin", 
                        email: "admin@misk.org.in",
                        designation: "Administrator",
                        status: "Active", 
                        joined: "2025-08-19",
                        avatar: "SA"
                    },
                    {
                        name: "Syed Azeez Ahmad",
                        email: "syed.azeez.ahmed@gmail.com", 
                        designation: "Volunteer",
                        status: "Active",
                        joined: "2025-08-19",
                        avatar: "AA"
                    }
                ],
                initiatives: [
                    {
                        title: "Masjid Project Phase 2 — Construction",
                        description: "Construction phase of the MISK Masjid project.",
                        status: "active",
                        category: "infrastructure", 
                        goal: "₹2 Cr",
                        raised: "₹2.7 Lakh",
                        progress: 1,
                        execution: 38
                    }
                ],
                campaigns: [
                    {
                        title: "Social Media Campaign - Phase 2",
                        description: "Awareness and donations via social channels.",
                        type: "online",
                        status: "Public",
                        featured: true,
                        initiative: "Masjid Project Phase 2 — Construction"
                    },
                    {
                        title: "Email/Newsletter Drive", 
                        description: "Periodic donor updates and appeals.",
                        type: "online",
                        status: "Public",
                        featured: false,
                        initiative: "Masjid Project Phase 2 — Construction"
                    },
                    {
                        title: "Special Gathering",
                        description: "In-person fundraising event.",
                        type: "offline", 
                        status: "Private",
                        featured: false,
                        initiative: "Masjid Project Phase 2 — Construction"
                    }
                ],
                tasks: [
                    {
                        title: "Draft social media calendar",
                        description: "Content plan for next 4 weeks (FB/IG/Twitter).",
                        status: "pending",
                        priority: "high",
                        assignee: "Muhammad Tanveerullah",
                        dueDate: "2025-08-30"
                    },
                    {
                        title: "Create donor pledge form", 
                        description: "Online + printable versions.",
                        status: "pending",
                        priority: "medium",
                        assignee: "Syed Azeez Ahmad",
                        dueDate: "2025-09-01"
                    },
                    {
                        title: "Book venue for special gathering",
                        description: "Coordinate with partners and lock date.",
                        status: "pending", 
                        priority: "high",
                        assignee: "Super Admin",
                        dueDate: "2025-08-25"
                    }
                ],
                donations: [
                    {
                        donor: "Demo User 3",
                        amount: "₹25,000",
                        method: "Bank Transfer",
                        status: "confirmed", 
                        reconciled: true,
                        date: "2025-08-20",
                        initiative: "Demo Donations — Showcase"
                    },
                    {
                        donor: "Demo User 1",
                        amount: "₹1,500", 
                        method: "UPI",
                        status: "confirmed",
                        reconciled: false,
                        date: "2025-08-19",
                        initiative: "Demo Donations — Showcase"
                    }
                ],
                kpis: {
                    users: 3,
                    roles: 5, 
                    initiatives: 8,
                    campaigns: 5,
                    tasks: 3,
                    events: 0
                }
            }
        };
        
        this.init();
    }
    
    init() {
        this.renderLanding();
        this.bindEvents();
    }
    
    bindEvents() {
        // Back button
        document.getElementById('backBtn').addEventListener('click', () => {
            if (this.currentScreen === 'screenDisplay') {
                this.showCategory(this.currentCategory);
            } else if (this.currentScreen === 'category') {
                this.showLanding();
            }
        });
        
        // Modal close
        document.getElementById('closeModal').addEventListener('click', () => {
            this.closeModal();
        });
        
        document.getElementById('modal').addEventListener('click', (e) => {
            if (e.target.classList.contains('modal-backdrop')) {
                this.closeModal();
            }
        });
    }
    
    showScreen(screenId) {
        document.querySelectorAll('.screen').forEach(screen => {
            screen.classList.remove('active');
        });
        document.getElementById(screenId).classList.add('active');
        this.currentScreen = screenId;
        
        // Update back button visibility
        const backBtn = document.getElementById('backBtn');
        if (screenId === 'landing') {
            backBtn.classList.add('hidden');
        } else {
            backBtn.classList.remove('hidden');
        }
    }
    
    showLanding() {
        this.showScreen('landing');
        this.currentCategory = null;
        this.currentScreenName = null;
    }
    
    showCategory(categoryId) {
        const category = this.data.categories.find(cat => cat.id === categoryId);
        if (!category) return;
        
        this.currentCategory = categoryId;
        document.getElementById('categoryTitle').textContent = category.name;
        document.getElementById('categoryDescription').textContent = category.description;
        
        this.renderScreensList(category.screens);
        this.showScreen('category');
    }
    
    showIndividualScreen(categoryId, screenName) {
        this.currentCategory = categoryId;
        this.currentScreenName = screenName;
        document.getElementById('screenTitle').textContent = screenName;
        
        this.renderScreenContent(categoryId, screenName);
        this.showScreen('screenDisplay');
    }
    
    renderLanding() {
        const grid = document.getElementById('categoriesGrid');
        grid.innerHTML = this.data.categories.map(category => `
            <div class="category-card" onclick="app.showCategory('${category.id}')">
                <span class="category-icon">${category.icon}</span>
                <h3 class="category-name">${category.name}</h3>
                <p class="category-screens">${category.screens.length} screens</p>
            </div>
        `).join('');
    }
    
    renderScreensList(screens) {
        const list = document.getElementById('screensList');
        list.innerHTML = screens.map(screen => `
            <div class="screen-card" onclick="app.showIndividualScreen('${this.currentCategory}', '${screen}')">
                <h3 class="screen-card-title">${screen}</h3>
                <p class="screen-card-description">View ${screen.toLowerCase()} interface</p>
            </div>
        `).join('');
    }
    
    renderScreenContent(categoryId, screenName) {
        const content = document.getElementById('screenContent');
        
        switch (categoryId) {
            case 'auth':
                content.innerHTML = this.renderAuthScreen(screenName);
                break;
            case 'dashboard':
                content.innerHTML = this.renderDashboardScreen(screenName);
                break;
            case 'users':
                content.innerHTML = this.renderUsersScreen(screenName);
                break;
            case 'roles':
                content.innerHTML = this.renderRolesScreen(screenName);
                break;
            case 'initiatives':
                content.innerHTML = this.renderInitiativesScreen(screenName);
                break;
            case 'campaigns':
                content.innerHTML = this.renderCampaignsScreen(screenName);
                break;
            case 'tasks':
                content.innerHTML = this.renderTasksScreen(screenName);
                break;
            case 'donations':
                content.innerHTML = this.renderDonationsScreen(screenName);
                break;
            case 'events':
                content.innerHTML = this.renderEventsScreen(screenName);
                break;
            case 'settings':
                content.innerHTML = this.renderSettingsScreen(screenName);
                break;
            default:
                content.innerHTML = '<p>Screen not implemented yet.</p>';
        }
        
        this.bindScreenEvents();
    }
    
    renderAuthScreen(screenName) {
        switch (screenName) {
            case 'Login':
                return `
                    <div class="form-section" style="padding: 2rem; max-width: 400px; margin: 0 auto;">
                        <h2 class="form-section-title text-center">Sign In to MISK ERP</h2>
                        <form>
                            <div class="form-group">
                                <label>Email Address</label>
                                <input type="email" placeholder="Enter your email" value="admin@misk.org.in">
                            </div>
                            <div class="form-group">
                                <label>Password</label>
                                <input type="password" placeholder="Enter your password">
                            </div>
                            <div class="form-group" style="display: flex; align-items: center; gap: 8px;">
                                <input type="checkbox" id="remember">
                                <label for="remember" style="margin: 0;">Remember me</label>
                            </div>
                            <button type="button" class="btn btn--primary btn--full-width mb-16">Sign In</button>
                            <button type="button" class="btn btn--outline btn--full-width mb-16">
                                Continue with Google
                            </button>
                            <p class="text-center text-sm">
                                <a href="#" onclick="app.showIndividualScreen('auth', 'Forgot Password')">Forgot your password?</a>
                            </p>
                        </form>
                    </div>
                `;
            case 'Forgot Password':
                return `
                    <div class="form-section" style="padding: 2rem; max-width: 400px; margin: 0 auto;">
                        <h2 class="form-section-title text-center">Reset Password</h2>
                        <p class="text-center mb-16">Enter your email address and we'll send you a link to reset your password.</p>
                        <form>
                            <div class="form-group">
                                <label>Email Address</label>
                                <input type="email" placeholder="Enter your email">
                            </div>
                            <button type="button" class="btn btn--primary btn--full-width mb-16">Send Reset Link</button>
                            <p class="text-center text-sm">
                                <a href="#" onclick="app.showIndividualScreen('auth', 'Login')">Back to Sign In</a>
                            </p>
                        </form>
                    </div>
                `;
            case 'App Lock':
                return `
                    <div class="form-section" style="padding: 2rem; max-width: 400px; margin: 0 auto;">
                        <h2 class="form-section-title text-center">Enter PIN</h2>
                        <p class="text-center mb-16">Enter your 4-digit PIN to access the app</p>
                        <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-bottom: 2rem;">
                            <input type="password" maxlength="1" style="text-align: center; font-size: 1.5rem; padding: 1rem;">
                            <input type="password" maxlength="1" style="text-align: center; font-size: 1.5rem; padding: 1rem;">
                            <input type="password" maxlength="1" style="text-align: center; font-size: 1.5rem; padding: 1rem;">
                            <input type="password" maxlength="1" style="text-align: center; font-size: 1.5rem; padding: 1rem;">
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; max-width: 300px; margin: 0 auto;">
                            ${[1,2,3,4,5,6,7,8,9,'',0,'⌫'].map(key => 
                                `<button type="button" class="btn btn--outline" style="padding: 1rem; font-size: 1.2rem;">${key}</button>`
                            ).join('')}
                        </div>
                    </div>
                `;
            default:
                return '<p>Auth screen not found.</p>';
        }
    }
    
    renderDashboardScreen(screenName) {
        switch (screenName) {
            case 'Main Dashboard':
                return `
                    <div style="padding: 2rem;">
                        <div class="welcome-banner" style="background: linear-gradient(135deg, #2F5233 0%, #4A7C59 100%); color: white; padding: 2rem; border-radius: 12px; margin-bottom: 2rem;">
                            <h2>As-salamu alaykum, Super Admin</h2>
                            <p>Welcome back to MISK EWT ERP. Here's your dashboard overview.</p>
                        </div>
                        
                        <h3 class="form-section-title">Key Metrics</h3>
                        <div class="kpi-grid">
                            <div class="kpi-card">
                                <div class="kpi-value">${this.data.sampleData.kpis.users}</div>
                                <div class="kpi-label">Users</div>
                            </div>
                            <div class="kpi-card">
                                <div class="kpi-value">${this.data.sampleData.kpis.roles}</div>
                                <div class="kpi-label">Roles</div>
                            </div>
                            <div class="kpi-card">
                                <div class="kpi-value">${this.data.sampleData.kpis.initiatives}</div>
                                <div class="kpi-label">Initiatives</div>
                            </div>
                            <div class="kpi-card">
                                <div class="kpi-value">${this.data.sampleData.kpis.campaigns}</div>
                                <div class="kpi-label">Campaigns</div>
                            </div>
                            <div class="kpi-card">
                                <div class="kpi-value">${this.data.sampleData.kpis.tasks}</div>
                                <div class="kpi-label">Tasks</div>
                            </div>
                            <div class="kpi-card">
                                <div class="kpi-value">${this.data.sampleData.kpis.events}</div>
                                <div class="kpi-label">Events</div>
                            </div>
                        </div>
                        
                        <h3 class="form-section-title">Recent Activity</h3>
                        <div class="misk-card">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                                <h4>Latest Donations</h4>
                                <a href="#" class="text-sm">View All</a>
                            </div>
                            ${this.data.sampleData.donations.map(donation => `
                                <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 0; border-bottom: 1px solid var(--color-border);">
                                    <div>
                                        <div class="font-semibold">${donation.donor}</div>
                                        <div class="text-sm" style="color: var(--color-text-secondary);">${donation.date}</div>
                                    </div>
                                    <div class="text-right">
                                        <div class="font-semibold" style="color: var(--misk-gold);">${donation.amount}</div>
                                        <div class="text-sm">${donation.method}</div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `;
            case 'Navigation Drawer':
                return `
                    <div style="padding: 2rem;">
                        <h3 class="form-section-title">Navigation Menu</h3>
                        <div style="max-width: 300px; background: var(--color-surface); border: 1px solid var(--color-border); border-radius: 12px;">
                            <div style="padding: 1.5rem; border-bottom: 1px solid var(--color-border);">
                                <div class="avatar" style="width: 60px; height: 60px; font-size: 1.5rem; margin-bottom: 1rem;">SA</div>
                                <div class="font-semibold">Super Admin</div>
                                <div class="text-sm" style="color: var(--color-text-secondary);">admin@misk.org.in</div>
                            </div>
                            <nav style="padding: 1rem 0;">
                                ${this.data.categories.map(category => `
                                    <a href="#" class="nav-item" style="display: flex; align-items: center; padding: 0.75rem 1.5rem; text-decoration: none; color: var(--color-text); transition: background 0.2s;">
                                        <span style="margin-right: 1rem;">${category.icon}</span>
                                        ${category.name}
                                    </a>
                                `).join('')}
                            </nav>
                        </div>
                    </div>
                `;
            default:
                return '<p>Dashboard screen not found.</p>';
        }
    }
    
    renderUsersScreen(screenName) {
        switch (screenName) {
            case 'Users List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search users..." style="margin: 0;">
                            <button class="filter-btn active">All Users</button>
                            <button class="filter-btn">Active</button>
                            <button class="filter-btn">Inactive</button>
                        </div>
                        
                        <div style="display: grid; gap: 1rem;">
                            ${this.data.sampleData.users.map(user => `
                                <div class="misk-card" style="display: flex; align-items: center; justify-content: space-between;">
                                    <div style="display: flex; align-items: center; gap: 1rem;">
                                        <div class="avatar">${user.avatar}</div>
                                        <div>
                                            <div class="font-semibold">${user.name}</div>
                                            <div class="text-sm" style="color: var(--color-text-secondary);">${user.email}</div>
                                        </div>
                                    </div>
                                    <div style="text-align: right;">
                                        <span class="misk-badge misk-badge--active">${user.designation}</span>
                                        <div class="text-sm" style="color: var(--color-text-secondary); margin-top: 0.25rem;">Joined ${user.joined}</div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                        
                        <button class="btn btn--primary" onclick="app.openModal('Add New User', app.getUserFormHTML())" style="margin-top: 1rem;">
                            Add New User
                        </button>
                    </div>
                `;
            case 'User Form':
                return `
                    <div style="padding: 2rem;">
                        <h3 class="form-section-title">User Information</h3>
                        ${this.getUserFormHTML()}
                    </div>
                `;
            default:
                return '<p>Users screen not found.</p>';
        }
    }
    
    renderRolesScreen(screenName) {
        switch (screenName) {
            case 'Roles List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search roles..." style="margin: 0;">
                            <button class="filter-btn active">All Roles</button>
                            <button class="filter-btn">Admin</button>
                            <button class="filter-btn">User</button>
                        </div>
                        
                        <div style="display: grid; gap: 1rem;">
                            ${['Super Admin', 'Project Manager', 'Volunteer', 'Donor', 'Guest'].map(role => `
                                <div class="misk-card">
                                    <div style="display: flex; justify-content: space-between; align-items: start;">
                                        <div>
                                            <h4 class="font-semibold mb-8">${role}</h4>
                                            <p class="text-sm mb-8" style="color: var(--color-text-secondary);">
                                                ${role === 'Super Admin' ? 'Full system access and administrative privileges' : 
                                                  role === 'Project Manager' ? 'Manage initiatives, campaigns, and tasks' :
                                                  role === 'Volunteer' ? 'Limited access to assigned tasks and events' :
                                                  role === 'Donor' ? 'View donation history and tax receipts' :
                                                  'Read-only access to public information'}
                                            </p>
                                            <span class="misk-badge misk-badge--active">
                                                ${role === 'Super Admin' ? '15' : role === 'Project Manager' ? '8' : role === 'Volunteer' ? '4' : role === 'Donor' ? '2' : '1'} permissions
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                        
                        <button class="btn btn--primary" onclick="app.openModal('Create New Role', app.getRoleFormHTML())" style="margin-top: 1rem;">
                            Create New Role
                        </button>
                    </div>
                `;
            case 'Role Form':
                return `
                    <div style="padding: 2rem;">
                        <h3 class="form-section-title">Role Configuration</h3>
                        ${this.getRoleFormHTML()}
                    </div>
                `;
            default:
                return '<p>Roles screen not found.</p>';
        }
    }
    
    renderInitiativesScreen(screenName) {
        switch (screenName) {
            case 'Initiatives List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search initiatives..." style="margin: 0;">
                            <button class="filter-btn active">All</button>
                            <button class="filter-btn">Active</button>
                            <button class="filter-btn">Completed</button>
                            <button class="filter-btn">Infrastructure</button>
                        </div>
                        
                        <div style="display: grid; gap: 1rem;">
                            ${this.data.sampleData.initiatives.map(initiative => `
                                <div class="misk-card">
                                    <h4 class="font-semibold mb-8">${initiative.title}</h4>
                                    <p class="text-sm mb-16" style="color: var(--color-text-secondary);">${initiative.description}</p>
                                    
                                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
                                        <div>
                                            <div class="text-sm" style="color: var(--color-text-secondary);">Financial Progress</div>
                                            <div class="progress-bar">
                                                <div class="progress-fill" style="width: ${initiative.progress}%;"></div>
                                            </div>
                                            <div class="text-sm font-semibold">${initiative.raised} / ${initiative.goal}</div>
                                        </div>
                                        <div>
                                            <div class="text-sm" style="color: var(--color-text-secondary);">Execution Progress</div>
                                            <div class="progress-bar">
                                                <div class="progress-fill" style="width: ${initiative.execution}%;"></div>
                                            </div>
                                            <div class="text-sm font-semibold">${initiative.execution}%</div>
                                        </div>
                                    </div>
                                    
                                    <div style="display: flex; justify-content: between; align-items: center;">
                                        <span class="misk-badge misk-badge--active">${initiative.status}</span>
                                        <span class="misk-badge misk-badge--medium">${initiative.category}</span>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                        
                        <button class="btn btn--primary" style="margin-top: 1rem;">Create New Initiative</button>
                    </div>
                `;
            case 'Initiative Detail':
                return `
                    <div style="padding: 2rem;">
                        <div class="misk-card">
                            <h2 class="font-bold mb-16">${this.data.sampleData.initiatives[0].title}</h2>
                            <p class="mb-16" style="color: var(--color-text-secondary);">${this.data.sampleData.initiatives[0].description}</p>
                            
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem; margin-bottom: 2rem;">
                                <div>
                                    <h4 class="font-semibold mb-8">Financial Goal</h4>
                                    <div class="text-lg font-bold" style="color: var(--misk-gold);">${this.data.sampleData.initiatives[0].goal}</div>
                                </div>
                                <div>
                                    <h4 class="font-semibold mb-8">Amount Raised</h4>
                                    <div class="text-lg font-bold" style="color: var(--misk-light-green);">${this.data.sampleData.initiatives[0].raised}</div>
                                </div>
                                <div>
                                    <h4 class="font-semibold mb-8">Execution</h4>
                                    <div class="text-lg font-bold">${this.data.sampleData.initiatives[0].execution}%</div>
                                </div>
                            </div>
                            
                            <h4 class="font-semibold mb-8">Progress Overview</h4>
                            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem;">
                                <div>
                                    <div class="text-sm mb-8" style="color: var(--color-text-secondary);">Financial Progress</div>
                                    <div class="progress-bar">
                                        <div class="progress-fill" style="width: ${this.data.sampleData.initiatives[0].progress}%;"></div>
                                    </div>
                                </div>
                                <div>
                                    <div class="text-sm mb-8" style="color: var(--color-text-secondary);">Execution Progress</div>
                                    <div class="progress-bar">
                                        <div class="progress-fill" style="width: ${this.data.sampleData.initiatives[0].execution}%;"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="misk-card">
                            <h4 class="font-semibold mb-16">Related Campaigns</h4>
                            ${this.data.sampleData.campaigns.map(campaign => `
                                <div style="display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 0; border-bottom: 1px solid var(--color-border);">
                                    <div>
                                        <div class="font-semibold">${campaign.title}</div>
                                        <div class="text-sm" style="color: var(--color-text-secondary);">${campaign.description}</div>
                                    </div>
                                    <div>
                                        <span class="misk-badge misk-badge--${campaign.type === 'online' ? 'active' : 'medium'}">${campaign.type}</span>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `;
            case 'Initiative Form':
                return `
                    <div style="padding: 2rem;">
                        ${this.getInitiativeFormHTML()}
                    </div>
                `;
            default:
                return '<p>Initiatives screen not found.</p>';
        }
    }
    
    renderCampaignsScreen(screenName) {
        switch (screenName) {
            case 'Campaigns List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search campaigns..." style="margin: 0;">
                            <button class="filter-btn active">All</button>
                            <button class="filter-btn">Online</button>
                            <button class="filter-btn">Offline</button>
                            <button class="filter-btn">Featured</button>
                        </div>
                        
                        <div style="display: grid; gap: 1rem;">
                            ${this.data.sampleData.campaigns.map(campaign => `
                                <div class="misk-card">
                                    <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 1rem;">
                                        <div>
                                            <h4 class="font-semibold mb-8">${campaign.title}</h4>
                                            <p class="text-sm mb-8" style="color: var(--color-text-secondary);">${campaign.description}</p>
                                        </div>
                                        ${campaign.featured ? '<span style="color: var(--misk-gold); font-size: 1.5rem;">⭐</span>' : ''}
                                    </div>
                                    
                                    <div style="display: flex; justify-content: space-between; align-items: center;">
                                        <div style="display: flex; gap: 0.5rem;">
                                            <span class="misk-badge misk-badge--${campaign.type === 'online' ? 'active' : 'medium'}">${campaign.type}</span>
                                            <span class="misk-badge misk-badge--${campaign.status === 'Public' ? 'active' : 'pending'}">${campaign.status}</span>
                                        </div>
                                        <div class="text-sm" style="color: var(--color-text-secondary);">
                                            Linked to: ${campaign.initiative}
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                        
                        <button class="btn btn--primary" style="margin-top: 1rem;">Create New Campaign</button>
                    </div>
                `;
            case 'Campaign Form':
                return `
                    <div style="padding: 2rem;">
                        ${this.getCampaignFormHTML()}
                    </div>
                `;
            default:
                return '<p>Campaigns screen not found.</p>';
        }
    }
    
    renderTasksScreen(screenName) {
        switch (screenName) {
            case 'Tasks List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search tasks..." style="margin: 0;">
                            <button class="filter-btn active">All Tasks</button>
                            <button class="filter-btn">My Tasks</button>
                            <button class="filter-btn">Pending</button>
                            <button class="filter-btn">Completed</button>
                        </div>
                        
                        <div style="display: grid; gap: 1rem;">
                            ${this.data.sampleData.tasks.map(task => `
                                <div class="misk-card">
                                    <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 1rem;">
                                        <div style="flex: 1;">
                                            <h4 class="font-semibold mb-8">${task.title}</h4>
                                            <p class="text-sm mb-8" style="color: var(--color-text-secondary);">${task.description}</p>
                                        </div>
                                        <span class="misk-badge misk-badge--${task.priority}">${task.priority}</span>
                                    </div>
                                    
                                    <div style="display: flex; justify-content: space-between; align-items: center;">
                                        <div style="display: flex; align-items: center; gap: 1rem;">
                                            <div class="avatar" style="width: 32px; height: 32px; font-size: 12px;">
                                                ${task.assignee.split(' ').map(n => n[0]).join('').substring(0,2)}
                                            </div>
                                            <div>
                                                <div class="text-sm font-semibold">${task.assignee}</div>
                                                <div class="text-sm" style="color: var(--color-text-secondary);">Due: ${task.dueDate}</div>
                                            </div>
                                        </div>
                                        <span class="misk-badge misk-badge--${task.status === 'pending' ? 'pending' : 'active'}">${task.status}</span>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                        
                        <button class="btn btn--primary" style="margin-top: 1rem;">Create New Task</button>
                    </div>
                `;
            case 'Task Form':
                return `
                    <div style="padding: 2rem;">
                        ${this.getTaskFormHTML()}
                    </div>
                `;
            default:
                return '<p>Tasks screen not found.</p>';
        }
    }
    
    renderDonationsScreen(screenName) {
        switch (screenName) {
            case 'Donations Entry':
                return `
                    <div style="padding: 2rem;">
                        ${this.getDonationEntryFormHTML()}
                    </div>
                `;
            case 'Donations List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search donations..." style="margin: 0;">
                            <button class="filter-btn active">All</button>
                            <button class="filter-btn">Confirmed</button>
                            <button class="filter-btn">Pending</button>
                            <button class="filter-btn">Reconciled</button>
                        </div>
                        
                        <div style="display: grid; gap: 1rem;">
                            ${this.data.sampleData.donations.map(donation => `
                                <div class="misk-card">
                                    <div style="display: flex; justify-content: space-between; align-items: start;">
                                        <div>
                                            <h4 class="font-semibold mb-8">${donation.donor}</h4>
                                            <p class="text-sm mb-8" style="color: var(--color-text-secondary);">
                                                ${donation.initiative}
                                            </p>
                                            <div class="text-sm" style="color: var(--color-text-secondary);">
                                                ${donation.date} • ${donation.method}
                                            </div>
                                        </div>
                                        <div class="text-right">
                                            <div class="font-bold text-lg" style="color: var(--misk-gold); margin-bottom: 0.5rem;">
                                                ${donation.amount}
                                            </div>
                                            <div style="display: flex; gap: 0.5rem;">
                                                <span class="misk-badge misk-badge--active">${donation.status}</span>
                                                ${donation.reconciled ? '<span class="misk-badge misk-badge--medium">reconciled</span>' : ''}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                        
                        <button class="btn btn--primary" style="margin-top: 1rem;" 
                                onclick="app.showIndividualScreen('donations', 'Donations Entry')">
                            Record New Donation
                        </button>
                    </div>
                `;
            default:
                return '<p>Donations screen not found.</p>';
        }
    }
    
    renderEventsScreen(screenName) {
        switch (screenName) {
            case 'Events List':
                return `
                    <div style="padding: 2rem;">
                        <div class="filter-bar">
                            <input type="search" class="search-input" placeholder="Search events..." style="margin: 0;">
                            <button class="filter-btn active">All Events</button>
                            <button class="filter-btn">Upcoming</button>
                            <button class="filter-btn">Past</button>
                            <button class="filter-btn">Announcements</button>
                        </div>
                        
                        <div class="text-center" style="padding: 3rem; color: var(--color-text-secondary);">
                            <div style="font-size: 3rem; margin-bottom: 1rem;">📅</div>
                            <h3>No Events Scheduled</h3>
                            <p>Create your first event or announcement to get started.</p>
                        </div>
                        
                        <button class="btn btn--primary" style="margin-top: 1rem;">Create New Event</button>
                    </div>
                `;
            case 'Event Form':
                return `
                    <div style="padding: 2rem;">
                        ${this.getEventFormHTML()}
                    </div>
                `;
            default:
                return '<p>Events screen not found.</p>';
        }
    }
    
    renderSettingsScreen(screenName) {
        switch (screenName) {
            case 'Global Settings':
                return `
                    <div style="padding: 2rem;">
                        ${this.getGlobalSettingsHTML()}
                    </div>
                `;
            case 'Payment Settings':
                return `
                    <div style="padding: 2rem;">
                        ${this.getPaymentSettingsHTML()}
                    </div>
                `;
            case 'Security Settings':
                return `
                    <div style="padding: 2rem;">
                        ${this.getSecuritySettingsHTML()}
                    </div>
                `;
            default:
                return '<p>Settings screen not found.</p>';
        }
    }
    
    // Form HTML generators
    getUserFormHTML() {
        return `
            <form>
                <div class="form-section">
                    <h4 class="form-section-title">Basic Information</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Full Name *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Email Address *</label>
                            <input type="email" required>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Phone Number</label>
                            <input type="tel">
                        </div>
                        <div class="form-group">
                            <label>Designation</label>
                            <input type="text">
                        </div>
                    </div>
                </div>
                
                <div class="form-section">
                    <h4 class="form-section-title">Account Settings</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Role</label>
                            <select>
                                <option>Select Role</option>
                                <option>Super Admin</option>
                                <option>Project Manager</option>
                                <option>Volunteer</option>
                                <option>Donor</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Status</label>
                            <select>
                                <option>Active</option>
                                <option>Inactive</option>
                            </select>
                        </div>
                    </div>
                </div>
                
                <button type="submit" class="btn btn--primary">Save User</button>
                <button type="button" class="btn btn--outline">Cancel</button>
            </form>
        `;
    }
    
    getRoleFormHTML() {
        return `
            <form>
                <div class="form-section">
                    <h4 class="form-section-title">Role Details</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Role Name *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Role Type</label>
                            <select>
                                <option>Admin</option>
                                <option>Manager</option>
                                <option>User</option>
                                <option>Guest</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea rows="3"></textarea>
                    </div>
                </div>
                
                <div class="form-section">
                    <h4 class="form-section-title">Permissions</h4>
                    ${['Users', 'Roles', 'Initiatives', 'Campaigns', 'Tasks', 'Donations', 'Events', 'Settings'].map(module => `
                        <div style="margin-bottom: 1rem; padding: 1rem; border: 1px solid var(--color-border); border-radius: 8px;">
                            <h5 class="font-semibold mb-8">${module}</h5>
                            <div style="display: flex; gap: 1rem;">
                                <label style="display: flex; align-items: center; gap: 0.5rem;">
                                    <input type="checkbox"> Read
                                </label>
                                <label style="display: flex; align-items: center; gap: 0.5rem;">
                                    <input type="checkbox"> Write
                                </label>
                                <label style="display: flex; align-items: center; gap: 0.5rem;">
                                    <input type="checkbox"> Delete
                                </label>
                            </div>
                        </div>
                    `).join('')}
                </div>
                
                <button type="submit" class="btn btn--primary">Save Role</button>
                <button type="button" class="btn btn--outline">Cancel</button>
            </form>
        `;
    }
    
    getInitiativeFormHTML() {
        return `
            <form>
                <div class="form-section">
                    <h4 class="form-section-title">Initiative Details</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Initiative Title *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Category</label>
                            <select>
                                <option>Infrastructure</option>
                                <option>Education</option>
                                <option>Healthcare</option>
                                <option>Social Welfare</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea rows="4"></textarea>
                    </div>
                </div>
                
                <div class="form-section">
                    <h4 class="form-section-title">Financial Goals</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Target Amount (₹) *</label>
                            <input type="number" required>
                        </div>
                        <div class="form-group">
                            <label>Currency</label>
                            <select>
                                <option>INR (₹)</option>
                                <option>USD ($)</option>
                                <option>EUR (€)</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Start Date</label>
                            <input type="date">
                        </div>
                        <div class="form-group">
                            <label>Target Date</label>
                            <input type="date">
                        </div>
                    </div>
                </div>
                
                <button type="submit" class="btn btn--primary">Create Initiative</button>
                <button type="button" class="btn btn--outline">Cancel</button>
            </form>
        `;
    }
    
    getCampaignFormHTML() {
        return `
            <form>
                <div class="form-section">
                    <h4 class="form-section-title">Campaign Details</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Campaign Name *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Campaign Type</label>
                            <select>
                                <option>Online</option>
                                <option>Offline</option>
                                <option>Hybrid</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea rows="3"></textarea>
                    </div>
                </div>
                
                <div class="form-section">
                    <h4 class="form-section-title">Linking & Visibility</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Link to Initiative</label>
                            <select>
                                <option>Select Initiative</option>
                                <option>Masjid Project Phase 2 — Construction</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Visibility</label>
                            <select>
                                <option>Public</option>
                                <option>Private</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label style="display: flex; align-items: center; gap: 0.5rem;">
                            <input type="checkbox"> Featured Campaign
                        </label>
                    </div>
                </div>
                
                <button type="submit" class="btn btn--primary">Create Campaign</button>
                <button type="button" class="btn btn--outline">Cancel</button>
            </form>
        `;
    }
    
    getTaskFormHTML() {
        return `
            <form>
                <div class="form-section">
                    <h4 class="form-section-title">Task Details</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Task Title *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Priority</label>
                            <select>
                                <option>High</option>
                                <option>Medium</option>
                                <option>Low</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea rows="4"></textarea>
                    </div>
                </div>
                
                <div class="form-section">
                    <h4 class="form-section-title">Assignment & Dates</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Assign to</label>
                            <select>
                                <option>Select User</option>
                                <option>Muhammad Tanveerullah</option>
                                <option>Super Admin</option>
                                <option>Syed Azeez Ahmad</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Due Date</label>
                            <input type="date">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Link to Initiative/Campaign</label>
                        <select>
                            <option>None</option>
                            <option>Masjid Project Phase 2 — Construction</option>
                            <option>Social Media Campaign - Phase 2</option>
                        </select>
                    </div>
                </div>
                
                <button type="submit" class="btn btn--primary">Create Task</button>
                <button type="button" class="btn btn--outline">Cancel</button>
            </form>
        `;
    }
    
    getDonationEntryFormHTML() {
        return `
            <div class="form-section">
                <h4 class="form-section-title">Record New Donation</h4>
                <form>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Initiative/Campaign *</label>
                            <select required>
                                <option>Select Initiative or Campaign</option>
                                <option>Masjid Project Phase 2 — Construction</option>
                                <option>Social Media Campaign - Phase 2</option>
                                <option>Special Gathering</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Donation Amount (₹) *</label>
                            <input type="number" required step="0.01" min="1">
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Donor Name *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Donor Email</label>
                            <input type="email">
                        </div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Payment Method *</label>
                            <select required>
                                <option>Select Method</option>
                                <option>Bank Transfer</option>
                                <option>UPI</option>
                                <option>Credit Card</option>
                                <option>Cash</option>
                                <option>Cheque</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Transaction Date *</label>
                            <input type="date" required>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>Transaction Reference/Notes</label>
                        <textarea rows="3" placeholder="Transaction ID, reference number, or additional notes..."></textarea>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label style="display: flex; align-items: center; gap: 0.5rem;">
                                <input type="checkbox"> Send tax receipt to donor
                            </label>
                        </div>
                        <div class="form-group">
                            <label style="display: flex; align-items: center; gap: 0.5rem;">
                                <input type="checkbox"> Mark as reconciled
                            </label>
                        </div>
                    </div>
                    
                    <button type="submit" class="btn btn--primary">Record Donation</button>
                    <button type="button" class="btn btn--outline">Cancel</button>
                </form>
            </div>
        `;
    }
    
    getEventFormHTML() {
        return `
            <form>
                <div class="form-section">
                    <h4 class="form-section-title">Event Details</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Event Title *</label>
                            <input type="text" required>
                        </div>
                        <div class="form-group">
                            <label>Event Type</label>
                            <select>
                                <option>Fundraising</option>
                                <option>Community Gathering</option>
                                <option>Educational</option>
                                <option>Announcement</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea rows="4"></textarea>
                    </div>
                </div>
                
                <div class="form-section">
                    <h4 class="form-section-title">Schedule & Location</h4>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Event Date *</label>
                            <input type="date" required>
                        </div>
                        <div class="form-group">
                            <label>Event Time</label>
                            <input type="time">
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Location</label>
                            <input type="text">
                        </div>
                        <div class="form-group">
                            <label>Max Attendees</label>
                            <input type="number">
                        </div>
                    </div>
                    <div class="form-group">
                        <label style="display: flex; align-items: center; gap: 0.5rem;">
                            <input type="checkbox"> Enable RSVP
                        </label>
                    </div>
                </div>
                
                <button type="submit" class="btn btn--primary">Create Event</button>
                <button type="button" class="btn btn--outline">Cancel</button>
            </form>
        `;
    }
    
    getGlobalSettingsHTML() {
        return `
            <div class="form-section">
                <h4 class="form-section-title">Organization Details</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>Organization Name</label>
                        <input type="text" value="MISK Foundation">
                    </div>
                    <div class="form-group">
                        <label>Registration Number</label>
                        <input type="text" value="REG/2023/MISK001">
                    </div>
                </div>
                <div class="form-group">
                    <label>Address</label>
                    <textarea rows="3">123 Main Street, Islamic Center
Bangalore, Karnataka 560001
India</textarea>
                </div>
            </div>
            
            <div class="form-section">
                <h4 class="form-section-title">Contact Information</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>Primary Email</label>
                        <input type="email" value="admin@misk.org.in">
                    </div>
                    <div class="form-group">
                        <label>Phone Number</label>
                        <input type="tel" value="+91 80 1234 5678">
                    </div>
                </div>
            </div>
            
            <div class="form-section">
                <h4 class="form-section-title">System Preferences</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>Default Currency</label>
                        <select>
                            <option selected>INR (₹)</option>
                            <option>USD ($)</option>
                            <option>EUR (€)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Date Format</label>
                        <select>
                            <option>DD-MM-YYYY</option>
                            <option selected>YYYY-MM-DD</option>
                            <option>MM/DD/YYYY</option>
                        </select>
                    </div>
                </div>
            </div>
            
            <button type="submit" class="btn btn--primary">Save Settings</button>
        `;
    }
    
    getPaymentSettingsHTML() {
        return `
            <div class="form-section">
                <h4 class="form-section-title">Bank Details</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>Bank Name</label>
                        <input type="text" value="State Bank of India">
                    </div>
                    <div class="form-group">
                        <label>Account Number</label>
                        <input type="text" value="1234567890">
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>IFSC Code</label>
                        <input type="text" value="SBIN0001234">
                    </div>
                    <div class="form-group">
                        <label>Account Holder Name</label>
                        <input type="text" value="MISK Foundation">
                    </div>
                </div>
            </div>
            
            <div class="form-section">
                <h4 class="form-section-title">UPI Configuration</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>UPI ID</label>
                        <input type="text" value="misk@paytm">
                    </div>
                    <div class="form-group">
                        <label style="display: flex; align-items: center; gap: 0.5rem;">
                            <input type="checkbox" checked> Enable UPI Payments
                        </label>
                    </div>
                </div>
            </div>
            
            <div class="form-section">
                <h4 class="form-section-title">Razorpay Integration</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>Razorpay Key ID</label>
                        <input type="text" value="rzp_test_1234567890">
                    </div>
                    <div class="form-group">
                        <label>Webhook Secret</label>
                        <input type="password" value="••••••••••••">
                    </div>
                </div>
                <div class="form-group">
                    <label style="display: flex; align-items: center; gap: 0.5rem;">
                        <input type="checkbox" checked> Enable Online Payments
                    </label>
                </div>
            </div>
            
            <button type="submit" class="btn btn--primary">Update Payment Settings</button>
        `;
    }
    
    getSecuritySettingsHTML() {
        return `
            <div class="form-section">
                <h4 class="form-section-title">App Lock Settings</h4>
                <div class="form-group">
                    <label style="display: flex; align-items: center; gap: 0.5rem;">
                        <input type="checkbox" checked> Enable App Lock
                    </label>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Lock Type</label>
                        <select>
                            <option selected>PIN</option>
                            <option>Password</option>
                            <option>Biometric</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Auto Lock After (minutes)</label>
                        <select>
                            <option>5</option>
                            <option selected>15</option>
                            <option>30</option>
                            <option>60</option>
                        </select>
                    </div>
                </div>
            </div>
            
            <div class="form-section">
                <h4 class="form-section-title">Session Management</h4>
                <div class="form-row">
                    <div class="form-group">
                        <label>Session Timeout (hours)</label>
                        <select>
                            <option>2</option>
                            <option>4</option>
                            <option selected>8</option>
                            <option>24</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Max Concurrent Sessions</label>
                        <input type="number" value="3" min="1" max="10">
                    </div>
                </div>
                <div class="form-group">
                    <label style="display: flex; align-items: center; gap: 0.5rem;">
                        <input type="checkbox" checked> Force logout on password change
                    </label>
                </div>
            </div>
            
            <div class="form-section">
                <h4 class="form-section-title">Data Backup</h4>
                <div class="form-group">
                    <label style="display: flex; align-items: center; gap: 0.5rem;">
                        <input type="checkbox" checked> Enable Automated Backup
                    </label>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label>Backup Frequency</label>
                        <select>
                            <option selected>Daily</option>
                            <option>Weekly</option>
                            <option>Monthly</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Backup Time</label>
                        <input type="time" value="02:00">
                    </div>
                </div>
            </div>
            
            <button type="submit" class="btn btn--primary">Save Security Settings</button>
        `;
    }
    
    bindScreenEvents() {
        // Filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
            });
        });
        
        // Navigation items hover effect
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('mouseenter', (e) => {
                e.target.style.background = 'rgba(218, 165, 32, 0.1)';
            });
            item.addEventListener('mouseleave', (e) => {
                e.target.style.background = 'transparent';
            });
        });
    }
    
    openModal(title, content) {
        document.getElementById('modalTitle').textContent = title;
        document.getElementById('modalBody').innerHTML = content;
        document.getElementById('modal').classList.remove('hidden');
        this.modalOpen = true;
    }
    
    closeModal() {
        document.getElementById('modal').classList.add('hidden');
        this.modalOpen = false;
    }
}

// Initialize the app
const app = new MiskERPApp();