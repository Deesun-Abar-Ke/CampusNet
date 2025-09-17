"""
Database utility functions for connection management
"""
import functools
from flask import current_app
from models import db
from sqlalchemy.exc import DisconnectionError, OperationalError
import time

def with_db_retry(max_retries=3, delay=1):
    """Decorator to retry database operations with exponential backoff"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            
            for attempt in range(max_retries):
                try:
                    # Ensure we have a clean session
                    if hasattr(db.session, 'remove'):
                        db.session.remove()
                    
                    result = func(*args, **kwargs)
                    
                    # Commit if there are pending changes
                    if db.session.dirty or db.session.new or db.session.deleted:
                        db.session.commit()
                    
                    return result
                    
                except (DisconnectionError, OperationalError) as e:
                    last_exception = e
                    current_app.logger.warning(f"Database connection error on attempt {attempt + 1}: {str(e)}")
                    
                    # Clean up the session
                    db.session.rollback()
                    db.session.remove()
                    
                    if attempt < max_retries - 1:
                        # Exponential backoff
                        time.sleep(delay * (2 ** attempt))
                        continue
                    else:
                        # Last attempt failed
                        current_app.logger.error(f"All database retry attempts failed: {str(e)}")
                        raise
                        
                except Exception as e:
                    # Non-connection errors, don't retry
                    db.session.rollback()
                    raise
                    
            # Should never reach here, but just in case
            if last_exception:
                raise last_exception
                
        return wrapper
    return decorator

def cleanup_db_session():
    """Clean up database session after request"""
    try:
        if db.session:
            db.session.remove()
    except Exception as e:
        current_app.logger.error(f"Error cleaning up database session: {e}")

def get_db_connection_info():
    """Get database connection pool information for monitoring"""
    try:
        engine = db.engine
        pool = engine.pool
        
        return {
            'pool_size': pool.size(),
            'checked_in': pool.checkedin(),
            'checked_out': pool.checkedout(),
            'overflow': pool.overflow(),
            # Note: invalid() method not available in newer SQLAlchemy versions
            'invalid': getattr(pool, 'invalid', lambda: 0)()
        }
    except Exception as e:
        current_app.logger.error(f"Error getting DB connection info: {e}")
        return None

def force_close_connections():
    """Force close all database connections (emergency use)"""
    try:
        # Close all connections in the pool
        db.session.remove()
        db.engine.dispose()
        current_app.logger.info("Force closed all database connections")
        return True
    except Exception as e:
        current_app.logger.error(f"Error force closing connections: {e}")
        return False
