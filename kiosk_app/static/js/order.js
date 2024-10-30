async function fetchWithErrorHandling(url, options = {}) {
    try {
        const response = await fetch(url, options);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        
        // Sprawdź czy odpowiedź zawiera błąd
        if (data.error) {
            throw new Error(data.error);
        }
        
        return data;
    } catch (error) {
        console.error('Fetch error:', error);
        // Przekaż błąd dalej, aby mógł być obsłużony przez wywołującą funkcję
        throw error;
    }
}

class OrderPage {
    constructor(orderId) {
        this.orderId = orderId;
        this.total = 0;
        this.orderItems = {};
        this.menuItems = [];
        this.inactivityTimer = null;
        this.inactivityTimeout = 10 * 60 * 1000;
        this.availabilityCheckInterval = 30 * 1000;
        this.translations = {};
        this.currentCategory = null;
        this.imageCache = new Map();
        this.availabilityCache = new Map();
        this.lastAvailabilityCheck = null;
        
        this.loadTranslations().then(() => {
            this.showLoader();
            this.initializeMenu().then(() => {
                this.hideLoader();
                this.initializeEventListeners();
                this.startMonitoring();
                
                this.restoreState();
                
                if (!this.currentCategory) {
                    const firstCategoryButton = document.querySelector('.order-category-button');
                    if (firstCategoryButton) {
                        this.handleCategoryClick(firstCategoryButton);
                    }
                } else {
                    const categoryButton = document.querySelector(`.order-category-button[data-category="${this.currentCategory}"]`);
                    if (categoryButton) {
                        this.handleCategoryClick(categoryButton);
                    }
                }

                this.initializeLanguageHandlers();
            });
        });
    }

    async loadTranslations() {
        try {
            const response = await fetch('/translations.json');
            this.translations = await response.json();
            
            this._ = (text) => {
                return this.translations[text] || text;
            };
        } catch (error) {
            console.error('Failed to load translations:', error);
            this._ = (text) => text;
        }
    }

    showLoader() {
        const productList = document.querySelector('.order-product-list');
        productList.innerHTML = '<div class="loader">Loading...</div>';
    }

    hideLoader() {
        const loader = document.querySelector('.loader');
        if (loader) {
            loader.remove();
        }
    }

    async initializeMenu() {
        try {
            const response = await fetchWithErrorHandling('/get_menu');
            console.log('Menu response:', response);
            
            if (response.menu && response.menu.menu_items) {
                this.menuItems = response.menu.menu_items;
                console.log('Menu items:', this.menuItems);
                await this.renderMenu();
                await this.loadImages();
                await this.checkItemAvailability();
            } else {
                console.error('Invalid menu structure:', response);
                throw new Error('Invalid menu structure');
            }
        } catch (error) {
            console.error('Error initializing menu:', error);
            showFlashMessage(this._('Failed to load menu'), 'error');
        }
    }

    async renderMenu() {
        const productList = document.querySelector('.order-product-list');
        let menuHTML = '';

        const lang = document.documentElement.lang;
        const langCode = lang === 'uk' ? 'ua' : lang;

        console.log('Rendering menu items:', this.menuItems);
        console.log('Current order items:', this.orderItems);

        for (const item of this.menuItems) {
            const category = typeof item.category === 'string' ? 
                item.category : 
                (item.category.value || item.category);
            
            const savedQuantity = this.orderItems[item.item_id] || 0;
            
            menuHTML += `
            <article class="order-product-item" data-category="${category}" data-item-id="${item.item_id}" style="display: none;">
                <div class="product-left-column">
                    <div class="order-product-image-container">
                        <img src="" 
                             data-image-filename="${item.image}"
                             alt="${item['name_' + langCode]}" 
                             class="order-product-image"
                             onerror="this.onerror=null; this.src='/static/images/placeholder.png'">
                    </div>
                    <div class="order-product-info">
                        <h3 class="order-product-name">${item['name_' + langCode]}</h3>
                        ${item['description_' + langCode] ? 
                            `<p class="order-product-description">${item['description_' + langCode]}</p>` : ''}
                        ${item['allergens_' + langCode] ? 
                            `<p class="order-product-allergens">${this._('Allergens')}: ${item['allergens_' + langCode]}</p>` : ''}
                    </div>
                </div>
                <div class="product-right-column">
                    <div class="price-container">
                        <p class="order-product-price">${this._('Price')}: ${item.price.toFixed(2)} ${this._('PLN')}</p>
                        <p class="order-item-total" data-item-id="${item.item_id}">
                            ${this._('Total')} ${(item.price * savedQuantity).toFixed(2)} ${this._('PLN')}
                        </p>
                    </div>
                    <div class="order-quantity-control">
                        <button class="decrease-quantity" data-item-id="${item.item_id}" ${savedQuantity <= 0 ? 'disabled' : ''}>-</button>
                        <span class="quantity" data-item-id="${item.item_id}">${savedQuantity}</span>
                        <button class="increase-quantity" data-item-id="${item.item_id}">+</button>
                    </div>
                </div>
            </article>
        `;
        }

        productList.innerHTML = menuHTML;

        this.updateProductAvailability();

        if (this.currentCategory) {
            document.querySelectorAll('.order-product-item').forEach(item => {
                const itemCategory = item.dataset.category.toLowerCase();
                item.style.display = itemCategory === this.currentCategory.toLowerCase() ? 'flex' : 'none';
            });
        }
    }

    updateTotal(newTotal) {
        this.total = newTotal;
        const totalButton = document.getElementById('proceed-to-summary');
        const template = totalButton.dataset.template;
        totalButton.textContent = template.replace('0.00', this.total.toFixed(2));
    }

    async updateQuantity(itemId, change) {
        try {
            console.log(`Updating quantity for item ${itemId} by ${change}`);

            const quantityElement = document.querySelector(`.quantity[data-item-id="${itemId}"]`);
            if (!quantityElement) {
                console.error('Quantity element not found');
                return;
            }

            const currentQuantity = parseInt(quantityElement.textContent) || 0;
            console.log('Current quantity:', currentQuantity);

            const availabilityData = this.availabilityCache.get(itemId.toString());
            const availableQuantity = availabilityData || 0;
            console.log('Available quantity:', availableQuantity);

            if (change > 0 && currentQuantity + change > availableQuantity) {
                showFlashMessage(this._('Maximum available quantity reached'), 'warning');
                return;
            }

            const endpoint = change > 0 ? '/add_to_order' : '/remove_from_order';
            const response = await fetchWithErrorHandling(endpoint, {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify({
                    order_id: this.orderId,
                    item_id: itemId,
                    quantity: Math.abs(change)
                })
            });

            console.log('Server response:', response);

            if (response.success) {
                const newQuantity = Math.max(0, currentQuantity + change);
                this.orderItems[itemId] = newQuantity;
                quantityElement.textContent = newQuantity;

                const orderTotal = await fetchWithErrorHandling(`/get_order_total?order_id=${this.orderId}`);
                this.updateTotal(orderTotal.total);

                const productItem = quantityElement.closest('.order-product-item');
                const decreaseButton = productItem.querySelector('.decrease-quantity');
                const increaseButton = productItem.querySelector('.increase-quantity');

                if (decreaseButton) {
                    decreaseButton.disabled = newQuantity <= 0;
                    decreaseButton.classList.toggle('active', newQuantity > 0);
                    decreaseButton.classList.toggle('disabled', newQuantity <= 0);
                }

                if (increaseButton) {
                    increaseButton.disabled = newQuantity >= availableQuantity;
                    increaseButton.classList.toggle('active', newQuantity < availableQuantity);
                    increaseButton.classList.toggle('disabled', newQuantity >= availableQuantity);
                }

                const itemTotalElement = productItem.querySelector(`.order-item-total[data-item-id="${itemId}"]`);
                if (itemTotalElement) {
                    const price = parseFloat(productItem.querySelector('.order-product-price').textContent.match(/\d+\.?\d*/)[0]);
                    const itemTotal = price * newQuantity;
                    itemTotalElement.textContent = `${this._('Total')} ${itemTotal.toFixed(2)} ${this._('PLN')}`;
                }
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
            showFlashMessage(this._('Failed to update quantity'), 'error');
        }
    }

    async checkItemAvailability() {
        try {
            const visibleItems = document.querySelectorAll('.order-product-item');
            const itemIds = Array.from(visibleItems).map(item => item.dataset.itemId);

            if (itemIds.length > 0) {
                const queryParams = itemIds.map(id => `item_ids=${id}`).join('&');
                const data = await fetchWithErrorHandling(`/get_available_quantities?${queryParams}`);
                if (data.available_items) {
                    data.available_items.forEach(item => {
                        this.availabilityCache.set(item.item_id.toString(), item.available_quantity);
                    });
                    this.lastAvailabilityCheck = Date.now();
                    
                    this.updateProductAvailability(data.available_items);
                }
            }
        } catch (error) {
            console.error('Error checking availability:', error);
        }
    }

    updateProductAvailability(availableItems = null) {
        if (!availableItems) {
            availableItems = Array.from(this.availabilityCache.entries()).map(([item_id, available_quantity]) => ({
                item_id: parseInt(item_id),
                available_quantity
            }));
        }

        const availabilityMap = new Map(
            availableItems.map(item => [item.item_id.toString(), parseInt(item.available_quantity)])
        );

        document.querySelectorAll('.order-product-item').forEach(productItem => {
            const itemId = productItem.dataset.itemId;
            const availableQuantity = availabilityMap.get(itemId) || 0;
            
            const increaseButton = productItem.querySelector('.increase-quantity');
            const decreaseButton = productItem.querySelector('.decrease-quantity');
            const quantityDisplay = productItem.querySelector('.quantity');
            
            if (!quantityDisplay) return;
            
            const currentQuantity = parseInt(quantityDisplay.textContent) || 0;

            if (decreaseButton) {
                const canDecrease = currentQuantity > 0;
                decreaseButton.disabled = !canDecrease;
                decreaseButton.classList.toggle('active', canDecrease);
                decreaseButton.classList.toggle('disabled', !canDecrease);
            }

            if (increaseButton) {
                const canIncrease = currentQuantity < availableQuantity;
                increaseButton.disabled = !canIncrease;
                increaseButton.classList.toggle('active', canIncrease);
                increaseButton.classList.toggle('disabled', !canIncrease);
            }
        });
    }

    handleCategoryClick(button) {
        console.log('Category clicked:', button.dataset.category);
        
        document.querySelectorAll('.order-category-button').forEach(btn => {
            btn.classList.remove('active');
        });
        
        button.classList.add('active');
        
        const selectedCategory = button.dataset.category;
        this.currentCategory = selectedCategory;
        const productList = document.querySelector('.order-product-list');
        
        console.log('Selected category:', selectedCategory);
        
        productList.classList.add('changing');
        
        setTimeout(async () => {
            if (selectedCategory === 'sum') {
                this.showOrderSummary();
            } else {
                // Jeśli jesteśmy w podsumowaniu, musimy najpierw przywrócić listę produktów
                if (productList.querySelector('.order-summary')) {
                    // Renderuj ponownie menu
                    await this.renderMenu();
                    
                    // Po wyrenderowaniu menu, pokaż odpowiednią kategorię
                    document.querySelectorAll('.order-product-item').forEach(item => {
                        const itemCategory = item.dataset.category.toLowerCase();
                        item.style.display = itemCategory === selectedCategory ? 'flex' : 'none';
                    });
                    
                    // Przywróć zdjęcia z cache'u
                    document.querySelectorAll('.order-product-image').forEach(img => {
                        const filename = img.dataset.imageFilename;
                        if (filename && this.imageCache.has(filename)) {
                            img.src = this.imageCache.get(filename);
                        }
                    });
                    
                    // Zainicjalizuj kontrolki ilości
                    this.initializeQuantityControls();
                    
                    // Zaktualizuj dostępność produktów
                    this.updateProductAvailability();
                } else {
                    // Standardowe przełączanie między kategoriami
                    document.querySelectorAll('.order-product-item').forEach(item => {
                        const itemCategory = item.dataset.category.toLowerCase();
                        item.style.display = itemCategory === selectedCategory ? 'flex' : 'none';
                    });
                    
                    this.updateProductAvailability();
                }
            }
            
            productList.classList.remove('changing');
        }, 300);
    }

    async showOrderSummary() {
        try {
            const productList = document.querySelector('.order-product-list');
            productList.innerHTML = '<div class="loader">Loading...</div>';
            
            const response = await fetchWithErrorHandling(`/get_order_summary?order_id=${this.orderId}`);
            console.log('Raw response:', response);
            console.log('Items in response:', response.summary.items);
            
            if (response.summary && Array.isArray(response.summary.items)) {
                let summaryHTML = '<div class="order-summary">';
                summaryHTML += `<h2>${this._('Order Summary')}</h2>`;
                summaryHTML += '<div class="summary-items">';
                
                // Wyświetlamy wszystkie produkty z zamówienia
                response.summary.items.forEach(item => {
                    const imageUrl = this.imageCache.get(item.image) || '/static/images/placeholder.png';
                    
                    summaryHTML += `
                        <article class="order-product-item" data-item-id="${item.id}">
                            <div class="product-left-column">
                                <div class="order-product-image-container">
                                    <img src="${imageUrl}" 
                                         alt="${item['name_' + document.documentElement.lang]}" 
                                         class="order-product-image">
                                </div>
                                <div class="order-product-info">
                                    <h3 class="order-product-name">${item['name_' + document.documentElement.lang]}</h3>
                                    ${item['description_' + document.documentElement.lang] ? 
                                        `<p class="order-product-description">${item['description_' + document.documentElement.lang]}</p>` : ''}
                                    ${item['allergens_' + document.documentElement.lang] ? 
                                        `<p class="order-product-allergens">${this._('Allergens')}: ${item['allergens_' + document.documentElement.lang]}</p>` : ''}
                                </div>
                            </div>
                            <div class="product-right-column">
                                <div class="price-container">
                                    <p class="order-product-price">${this._('Price')}: ${item.price.toFixed(2)} ${this._('PLN')}</p>
                                    <p class="order-item-total">
                                        ${this._('Total')} ${item.price.toFixed(2)} ${this._('PLN')}
                                    </p>
                                </div>
                                <div class="order-quantity-control">
                                    <span class="quantity">1</span>
                                </div>
                            </div>
                        </article>
                    `;
                });
                
                summaryHTML += `</div>
                    <div class="summary-total">
                        <h3>${this._('Total')}: ${this.total.toFixed(2)} ${this._('PLN')}</h3>
                    </div>
                </div>`;
                
                productList.innerHTML = summaryHTML;
            } else {
                throw new Error('Invalid summary data');
            }
        } catch (error) {
            console.error('Error showing order summary:', error);
            showFlashMessage(this._('Failed to load order summary'), 'error');
            
            const firstCategoryButton = document.querySelector('.order-category-button');
            if (firstCategoryButton) {
                this.handleCategoryClick(firstCategoryButton);
            }
        }
    }

    resetInactivityTimer() {
        console.log('Resetting inactivity timer');
        if (this.inactivityTimer) {
            clearTimeout(this.inactivityTimer);
        }
    
        this.inactivityTimer = setTimeout(() => {
            console.log('Inactivity timeout reached, canceling order');
            this.cancelOrder(true);
        }, this.inactivityTimeout);
    }

    async cancelOrder(isAutomatic = false) {
        const cancelButton = document.getElementById('cancel-order');
        const successMessage = cancelButton.dataset.successMessage;
        const errorMessage = cancelButton.dataset.errorMessage;

        try {
            cancelButton.disabled = true;

            const response = await fetchWithErrorHandling('/cancel_order', {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ 
                    order_id: this.orderId,
                    aps_id: document.body.dataset.apsId,
                    is_automatic: isAutomatic
                })
            });

            if (response.success) {
                if (!isAutomatic) {
                    showFlashMessage(successMessage, 'success');
                    await new Promise(resolve => setTimeout(resolve, 1000));
                }
                window.location.href = '/';
            } else {
                throw new Error(response.error || errorMessage);
            }
        } catch (error) {
            console.error('Error canceling order:', error);
            if (!isAutomatic) {
                showFlashMessage(error.message || errorMessage, 'error');
            }
            cancelButton.disabled = false;
        }
    }

    initializeEventListeners() {
        console.log('Initializing event listeners');

        this.initializeQuantityControls();

        document.querySelectorAll('.order-category-button').forEach(button => {
            button.addEventListener('click', () => this.handleCategoryClick(button));
        });

        const cancelButton = document.getElementById('cancel-order');
        if (cancelButton) {
            cancelButton.addEventListener('click', (e) => {
                e.preventDefault();
                this.cancelOrder();
            });
        }

        const proceedButton = document.getElementById('proceed-to-summary');
        proceedButton.addEventListener('click', () => {
            if (this.total > 0) {
                window.location.href = `/order/summary/${this.orderId}`;
            } else {
                showFlashMessage(proceedButton.dataset.emptyCartMessage, 'error');
            }
        });

        const events = ['touchstart', 'click', 'scroll', 'mousemove', 'keypress'];
        events.forEach(eventType => {
            document.addEventListener(eventType, () => {
                this.resetInactivityTimer();
            });
        });

        this.restoreState();
    }

    startMonitoring() {
        this.checkItemAvailability();
        setInterval(() => this.checkItemAvailability(), this.availabilityCheckInterval);
        this.resetInactivityTimer();
    }

    initializeLanguageHandlers() {
        document.querySelectorAll('.order-flag-button').forEach(button => {
            button.addEventListener('click', (e) => {
                e.preventDefault();
                const lang = button.querySelector('img').alt.toLowerCase();
                console.log('Language change clicked:', lang);
                this.changeLanguage(lang);
            });
        });
    }

    async changeLanguage(lang) {
        console.log('Changing language to:', lang);
        try {
            const response = await fetch('/set_language/' + lang, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                }
            });
            const data = await response.json();
            
            if (data.success) {
                // Aktualizuj język dokumentu
                document.documentElement.lang = lang === 'uk' ? 'uk' : lang;
                
                // Załaduj nowe tłumaczenia
                await this.loadTranslations();
                
                // Aktualizuj wszystkie teksty w interfejsie
                this.updateInterfaceTranslations();
                
                // Nie renderuj całego menu od nowa, tylko zaktualizuj teksty
                this.updateMenuTexts();
            }
        } catch (error) {
            console.error('Error changing language:', error);
            showFlashMessage(this._('Failed to change language'), 'error');
        }
    }

    restoreState() {
        const savedState = sessionStorage.getItem('orderState');
        if (savedState) {
            const state = JSON.parse(savedState);
            if (state.orderId === this.orderId) {
                this.total = state.total;
                this.orderItems = state.orderItems;
                this.currentCategory = state.currentCategory;
                
                if (state.imageCache) {
                    this.imageCache = new Map(state.imageCache);
                }
                
                if (this.currentCategory) {
                    const categoryButton = document.querySelector(`.order-category-button[data-category="${this.currentCategory}"]`);
                    if (categoryButton) {
                        document.querySelectorAll('.order-category-button').forEach(btn => {
                            btn.classList.remove('active');
                        });
                        categoryButton.classList.add('active');
                    }
                }
                
                this.updateDisplay();
            }
            sessionStorage.removeItem('orderState');
        }
    }

    updateDisplay() {
        Object.entries(this.orderItems).forEach(([itemId, quantity]) => {
            const quantityElement = document.querySelector(`.quantity[data-item-id="${itemId}"]`);
            if (quantityElement) {
                quantityElement.textContent = quantity;
            }
        });

        this.updateTotal(this.total);
    }

    async loadImages() {
        const images = document.querySelectorAll('.order-product-image');
        for (const img of images) {
            const filename = img.dataset.imageFilename;
            if (!filename) continue;

            try {
                if (this.imageCache.has(filename)) {
                    img.src = this.imageCache.get(filename);
                    continue;
                }

                const response = await fetch(`/get_public_image_url?filename=${filename}`);
                const data = await response.json();
                if (data.url) {
                    this.imageCache.set(filename, data.url);
                    img.src = data.url;
                }
            } catch (error) {
                console.error('Error loading image:', error);
                const fallbackSrc = img.getAttribute('onerror').match(/this\.src='([^']+)'/)[1];
                img.src = fallbackSrc;
                this.imageCache.set(filename, fallbackSrc);
            }
        }
    }

    clearImageCache() {
        this.imageCache.clear();
    }

    initializeQuantityControls() {
        console.log('Initializing quantity controls');

        document.querySelectorAll('.increase-quantity').forEach(button => {
            console.log('Adding increase listener for:', button);
            button.replaceWith(button.cloneNode(true));
            const newButton = document.querySelector(`.increase-quantity[data-item-id="${button.dataset.itemId}"]`);
            newButton.addEventListener('click', () => {
                console.log('Increase clicked for item:', newButton.dataset.itemId);
                this.updateQuantity(newButton.dataset.itemId, 1);
            });
        });

        document.querySelectorAll('.decrease-quantity').forEach(button => {
            console.log('Adding decrease listener for:', button);
            button.replaceWith(button.cloneNode(true));
            const newButton = document.querySelector(`.decrease-quantity[data-item-id="${button.dataset.itemId}"]`);
            newButton.addEventListener('click', () => {
                console.log('Decrease clicked for item:', newButton.dataset.itemId);
                this.updateQuantity(newButton.dataset.itemId, -1);
            });
        });
    }

    // Nowa metoda do aktualizacji tekstów w menu bez przeładowania
    updateMenuTexts() {
        const lang = document.documentElement.lang;
        const langCode = lang === 'uk' ? 'ua' : lang;

        document.querySelectorAll('.order-product-item').forEach(item => {
            const itemId = item.dataset.itemId;
            const menuItem = this.menuItems.find(mi => mi.item_id.toString() === itemId);
            
            if (menuItem) {
                // Aktualizuj nazwę produktu
                const nameElement = item.querySelector('.order-product-name');
                if (nameElement) {
                    nameElement.textContent = menuItem[`name_${langCode}`];
                }

                // Aktualizuj opis produktu
                const descElement = item.querySelector('.order-product-description');
                if (descElement && menuItem[`description_${langCode}`]) {
                    descElement.textContent = menuItem[`description_${langCode}`];
                }

                // Aktualizuj alergeny
                const allergenElement = item.querySelector('.order-product-allergens');
                if (allergenElement && menuItem[`allergens_${langCode}`]) {
                    allergenElement.textContent = `${this._('Allergens')}: ${menuItem[`allergens_${langCode}`]}`;
                }

                // Aktualizuj cenę
                const priceElement = item.querySelector('.order-product-price');
                if (priceElement) {
                    priceElement.textContent = `${this._('Price')}: ${menuItem.price.toFixed(2)} ${this._('PLN')}`;
                }

                // Aktualizuj sumę dla produktu
                const quantity = parseInt(item.querySelector('.quantity').textContent) || 0;
                const totalElement = item.querySelector('.order-item-total');
                if (totalElement) {
                    totalElement.textContent = `${this._('Total')} ${(menuItem.price * quantity).toFixed(2)} ${this._('PLN')}`;
                }
            }
        });
    }

    updateInterfaceTranslations() {
        // Aktualizuj przyciski kategorii
        const categoryTranslations = {
            'snack': this._('Snacks'),
            'drink': this._('Drinks'),
            'coffee': this._('Coffee'),
            'take_away_box': this._('Take Away'),
            'sauce': this._('Sauces'),
            'sum': this._('Summary')
        };

        document.querySelectorAll('.order-category-button').forEach(button => {
            const category = button.dataset.category;
            if (categoryTranslations[category]) {
                button.textContent = categoryTranslations[category];
            }
        });

        // Aktualizuj przycisk anulowania
        const cancelButton = document.getElementById('cancel-order');
        if (cancelButton) {
            cancelButton.textContent = this._('Cancel');
        }

        // Aktualizuj szacowany czas oczekiwania
        const estimatedTimeElement = document.querySelector('.order-estimated-time');
        if (estimatedTimeElement) {
            const time = parseInt(estimatedTimeElement.dataset.time || '0');
            estimatedTimeElement.textContent = this._('Estimated waiting time: %(time)d min').replace('%(time)d', time);
        }

        // Aktualizuj przycisk podsumowania
        const proceedButton = document.getElementById('proceed-to-summary');
        if (proceedButton) {
            proceedButton.textContent = `${this._('Total')} ${this.total.toFixed(2)} ${this._('PLN')}`;
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const orderContainer = document.querySelector('.order-container');
    if (orderContainer) {
        const orderId = orderContainer.dataset.orderId;
        new OrderPage(orderId);
    }
});
