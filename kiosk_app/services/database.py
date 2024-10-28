from app.errors import DatabaseError
from functools import lru_cache
from config import Config
from app.models import (
    APSMenuItems, APSMenuItem, AvailableItem, APSOrder, APSOrderWithItems,
    SuggestedProduct, EstimatedWaitingTime, ItemCategory, OrderStatus, ItemStatus
)
from typing import List, Dict, Any
import json
from services.logging_service import logging_service

class Database:
    def __init__(self):
        self.client = Config.get_local_client()

    def get_available_items(self, aps_id: int, item_ids: List[int]) -> List[AvailableItem]:
        try:
            result = self.client.rpc('get_available_items', {
                'aps_id_input': aps_id,
                'item_ids': item_ids
            }).execute()
            
            if result.data:
                return [AvailableItem(**item) for item in result.data]
            return []
        except Exception as e:
            logging_service.error(f"Database error in get_available_items: {str(e)}")
            raise DatabaseError("Error getting available items")

    def get_order_total(self, order_id: int, aps_id: int) -> float:
        try:
            result = self.client.rpc('get_order_total', {
                'input_order_id': order_id,
                'input_aps_id': aps_id
            }).execute()
            
            return float(result.data[0]['get_order_total'])
        except Exception as e:
            logging_service.error(f"Database error in get_order_total: {str(e)}")
            raise DatabaseError("Error getting order total")

    def generate_next_kds_order_number(self, aps_id: int) -> int:
        try:
            result = self.client.rpc('generate_next_kds_order_number', {
                'input_aps_id': aps_id
            }).execute()
            
            return int(result.data[0]['generate_next_kds_order_number'])
        except Exception as e:
            logging_service.error(f"Database error in generate_next_kds_order_number: {str(e)}")
            raise DatabaseError("Error generating KDS order number")

    def calculate_estimated_waiting_time(self, aps_id: int, order_id: int = None) -> int:
        """
        Oblicza szacowany czas oczekiwania dla zamówienia lub ogólny czas kolejki.
        
        Args:
            aps_id (int): ID kiosku APS
            order_id (int, optional): ID zamówienia, jeśli None to oblicza tylko czas kolejki
        
        Returns:
            int: Szacowany czas oczekiwania w minutach
        """
        try:
            # Wywołujemy funkcję SQL z odpowiednimi parametrami
            result = self.client.rpc(
                'calculate_estimated_waiting_time',
                {
                    'input_aps_id': aps_id,
                    'input_order_id': order_id
                }
            ).execute()
            
            # Sprawdzamy czy mamy wynik
            if not result.data:
                return 0
                
            try:
                return int(result.data)
            except (ValueError, TypeError, IndexError) as e:
                logging_service.error(f"Invalid waiting time value or format: {str(e)}")
                return 0
                
        except Exception as e:
            logging_service.error(f"Database error in calculate_estimated_waiting_time: {str(e)}")
            return 0  # Zwracamy 0 w przypadku błędu

    def get_suggested_products(self, aps_id: int, order_id: int, max_suggestions: int = 5) -> List[SuggestedProduct]:
        try:
            result = self.client.rpc('get_suggested_products', {
                'input_aps_id': aps_id,
                'input_order_id': order_id,
                'max_suggestions': max_suggestions
            }).execute()
            
            if result.data:
                return [SuggestedProduct(**product) for product in result.data]
            return []
        except Exception as e:
            logging_service.error(f"Database error in get_suggested_products: {str(e)}")
            raise DatabaseError("Error getting suggested products")

    @lru_cache(maxsize=128)
    def get_menu(self, aps_id: int) -> APSMenuItems:
        try:
            result = self.client.table('aps_menu_items').select('*').eq('aps_id', aps_id).execute()
            
            if result.data:
                menu_data = result.data[0]
                menu_items = [APSMenuItem(**item) for item in menu_data['menu_items']]
                return APSMenuItems(
                    aps_id=menu_data['aps_id'],
                    aps_name=menu_data['aps_name'],
                    menu_id=menu_data['menu_id'],
                    menu_name=menu_data['menu_name'],
                    menu_items=menu_items
                )
            raise DatabaseError("Menu not found")
        except Exception as e:
            logging_service.error(f"Database error in get_menu: {str(e)}")
            raise DatabaseError("Error getting menu")

    def get_aps_state(self, aps_id: int) -> str:
        try:
            result = self.client.table('aps_description').select('state').eq('id', aps_id).execute()
            if result.data:
                state = result.data[0]['state']
                logging_service.info(f"APS state retrieved: {state}")
                return state
            raise DatabaseError("APS state not found")
        except Exception as e:
            logging_service.error(f"Database error in get_aps_state: {str(e)}")
            raise DatabaseError("Error getting APS state")

    def create_order(self, aps_id: int) -> APSOrder:
        try:
            result = self.client.table('aps_order').insert({
                'aps_id': aps_id,
                'origin': 'kiosk',
                'status': 'during_ordering'
            }).execute()
            
            if result.data:
                return APSOrder(**result.data[0])
            raise DatabaseError("Failed to create order")
        except Exception as e:
            logging_service.error(f"Database error in create_order: {str(e)}")
            raise DatabaseError("Error creating order")

    def get_order_items(self, order_id: int) -> List[Dict[str, Any]]:
        try:
            result = self.client.table('aps_order_item').select('*').eq('aps_order_id', order_id).execute()
            
            return result.data
        except Exception as e:
            logging_service.error(f"Database error in get_order_items: {str(e)}")
            raise DatabaseError("Error getting order items")

    def add_item_to_order(self, order_id: int, item_id: int, quantity: int) -> bool:
        try:
            items_to_insert = [{'aps_order_id': order_id, 'item_id': item_id, 'status': 'reserved'} for _ in range(quantity)]
            self.client.table('aps_order_item').insert(items_to_insert).execute()
            return True
        except Exception as e:
            logging_service.error(f"Database error in add_item_to_order: {str(e)}")
            raise DatabaseError("Error adding item to order")

    def remove_item_from_order(self, order_id: int, item_id: int, quantity: int) -> bool:
        try:
            items_to_remove = self.client.table('aps_order_item').select('id').eq('aps_order_id', order_id).eq('item_id', item_id).eq('status', 'reserved').limit(quantity).execute()
            
            if items_to_remove.data:
                ids_to_remove = [item['id'] for item in items_to_remove.data]
                self.client.table('aps_order_item').delete().in_('id', ids_to_remove).execute()
            return True
        except Exception as e:
            logging_service.error(f"Database error in remove_item_from_order: {str(e)}")
            raise DatabaseError("Error removing item from order")

    def get_order_summary(self, order_id: int) -> APSOrderWithItems:
        try:
            result = self.client.table('aps_order_with_items').select('*').eq('id', order_id).execute()
            
            if result.data:
                return APSOrderWithItems(**result.data[0])
            raise DatabaseError("Order summary not found")
        except Exception as e:
            logging_service.error(f"Database error in get_order_summary: {str(e)}")
            raise DatabaseError("Error getting order summary")

    def get_order_details(self, order_id: int) -> APSOrder:
        try:
            result = self.client.table('aps_order').select('*').eq('id', order_id).execute()
            
            if result.data:
                return APSOrder(**result.data[0])
            raise DatabaseError("Order details not found")
        except Exception as e:
            logging_service.error(f"Database error in get_order_details: {str(e)}")
            raise DatabaseError("Error getting order details")

    def update_order_status(self, order_id: int, status: OrderStatus) -> bool:
        try:
            self.client.table('aps_order').update({'status': status.value}).eq('id', order_id).execute()
            return True
        except Exception as e:
            logging_service.error(f"Database error in update_order_status: {str(e)}")
            raise DatabaseError("Error updating order status")

    def update_order_kds_number(self, order_id: int, kds_number: int) -> bool:
        try:
            self.client.table('aps_order').update({'kds_order_number': kds_number}).eq('id', order_id).execute()
            return True
        except Exception as e:
            logging_service.error(f"Database error in update_order_kds_number: {str(e)}")
            raise DatabaseError("Error updating order KDS number")

    def get_order_details_by_kds(self, aps_id: int, kds_number: int) -> APSOrderWithItems:
        try:
            result = self.client.table('aps_order_with_items').select('*').eq('aps_id', aps_id).eq('kds_order_number', kds_number).execute()
            
            if result.data:
                return APSOrderWithItems(**result.data[0])
            raise DatabaseError("Order details not found")
        except Exception as e:
            logging_service.error(f"Database error in get_order_details_by_kds: {str(e)}")
            raise DatabaseError("Error getting order details by KDS")

    def get_order_with_items(self, order_id: int) -> APSOrderWithItems:
        try:
            result = self.client.table('aps_order_with_items').select('*').eq('id', order_id).execute()
            
            if result.data:
                return APSOrderWithItems(**result.data[0])
            raise DatabaseError("Order with items not found")
        except Exception as e:
            logging_service.error(f"Database error in get_order_with_items: {str(e)}")
            raise DatabaseError("Error getting order with items")

    def check_category_availability(self, aps_id: int, category: str) -> bool:
        try:
            # Pobierz wszystkie ID produktów z danej kategorii z menu
            menu = self.get_menu(aps_id)
            category_item_ids = [
                item.item_id 
                for item in menu.menu_items 
                if item.category.value == category
            ]
            
            if not category_item_ids:
                return False
                
            # Użyj istniejącej funkcji get_available_items do sprawdzenia dostępności
            available_items = self.get_available_items(aps_id, category_item_ids)
            
            # Sprawdź czy jakikolwiek produkt z kategorii jest dostępny
            return any(
                item.available_quantity > 0 
                for item in available_items
            )
            
        except Exception as e:
            logging_service.error(f"Database error in check_category_availability: {str(e)}")
            raise DatabaseError("Error checking category availability")

db = Database()
