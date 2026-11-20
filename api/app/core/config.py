from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración leída de variables de entorno o del archivo .env"""

    database_url: str = "mysql+pymysql://root:root@localhost:3306/blog_db"
    secret_key: str = "dev-secret-cambiar-en-produccion"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
