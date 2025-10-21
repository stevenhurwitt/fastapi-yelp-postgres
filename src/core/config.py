from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database settings
    database_host: str = "localhost"
    database_port: int = 5433
    database_user: str = "postgres"
    database_password: str = ""
    database_name: str = "postgres"
    
    # API settings
    api_title: str = "Yelp Data API"
    api_description: str = "FastAPI backend for querying Yelp database"
    api_version: str = "1.0.0"
    
    # Server settings
    api_host: str = "127.0.0.1"
    api_port: int = 8000
    debug: bool = False
    
    class Config:
        env_file = ".env"
        case_sensitive = False
    
    @property
    def database_url(self) -> str:
        """Construct database URL from individual components"""
        return f"postgresql://{self.database_user}:{self.database_password}@{self.database_host}:{self.database_port}/{self.database_name}"

settings = Settings()