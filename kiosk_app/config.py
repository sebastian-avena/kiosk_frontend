import os
from dotenv import load_dotenv, get_key
from supabase import create_client, Client

from services.logging_service import logging_service

# Load environment variables from .env file
load_dotenv()

class Config:
    LANGUAGES = ["en", "pl", "uk"]
    BABEL_DEFAULT_LOCALE = "pl"
    # Poprawiona ścieżka do katalogu translations
    BABEL_TRANSLATION_DIRECTORIES = "translations"
    
    SENTRY_DSN = os.environ.get("SENTRY_DSN")
    APS_ID = os.environ.get("APS_ID")
    
    # Secret key for Flask sessions
    SECRET_KEY = os.environ.get("SECRET_KEY") or "your-secret-key-here"
    
    # Supabase configuration
    SUPABASE_LOCAL_URL = os.environ.get("SUPABASE_LOCAL_URL")
    SUPABASE_LOCAL_KEY = os.environ.get("SUPABASE_LOCAL_KEY")
    SUPABASE_CENTRAL_URL = os.environ.get("SUPABASE_CENTRAL_URL")
    SUPABASE_CENTRAL_KEY = os.environ.get("SUPABASE_CENTRAL_KEY")
    
    # ELAVON configuration
    TERMINAL_ELAVON_IP = os.environ.get("TERMINAL_ELAVON_IP")
    TERMINAL_ELAVON_PORT_STATE = int(os.environ.get("TERMINAL_ELAVON_PORT_STATE"))
    TERMINAL_ELAVON_PORT_PAYMENT = int(os.environ.get("TERMINAL_ELAVON_PORT_PAYMENT"))
    
    FLASK_MODE = os.environ.get("FLASK_MODE")
    
    @staticmethod
    def get_local_client() -> Client:
        logging_service.info(f'SUPABASE_LOCAL_URL: {os.environ.get("SUPABASE_LOCAL_URL")}')
        return create_client(Config.SUPABASE_LOCAL_URL, Config.SUPABASE_LOCAL_KEY)

    @staticmethod
    def get_central_client() -> Client:
        logging_service.info(f"SUPABASE_CENTRAL_URL: {Config.SUPABASE_CENTRAL_URL}")
        return create_client(Config.SUPABASE_CENTRAL_URL, Config.SUPABASE_CENTRAL_KEY)

    @staticmethod
    def is_development_mode() -> bool:
        return Config.FLASK_MODE == "development"
    
    @staticmethod
    def is_production_mode() -> bool:
        return Config.FLASK_MODE == "production"
