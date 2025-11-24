# Copilot Instructions for ci-test

## Project Overview
This is a sample FastAPI application designed for CI/CD testing and demonstration purposes. The application is a simple REST API built with Python and FastAPI framework.

## Technology Stack
- **Language**: Python 3.11+
- **Framework**: FastAPI 0.95.2
- **Server**: Uvicorn 0.22.0 with standard extras (httptools, uvloop, watchfiles, websockets)
- **Testing**: pytest 7.4.2 with httpx 0.25.0 for API testing
- **Containerization**: Docker
- **Code Coverage**: coverage 7.2.6

## Project Structure
```
.
├── app/                 # Application source code
│   ├── __init__.py
│   └── main.py         # Main FastAPI application
├── tests/              # Test files
│   └── test_main.py    # API endpoint tests
├── .github/
│   └── workflows/      # GitHub Actions workflows
├── requirements.txt    # Python dependencies
├── setup.cfg          # Package configuration
└── Dockerfile         # Container definition
```

## Code Style and Conventions
- Follow PEP 8 style guidelines for Python code
- Use type hints for function parameters and return values
- Use Pydantic models for request/response validation
- Keep functions focused and single-purpose
- Use descriptive variable and function names

## API Endpoints
The application provides the following endpoints:
- `GET /` - Root endpoint with welcome message
- `GET /health` - Health check endpoint
- `POST /max` - Compute maximum value from a list of numbers

## Testing Requirements
- **Framework**: Use pytest for all tests
- **Test Client**: Use FastAPI's TestClient for API testing
- **Coverage**: Maintain test coverage using coverage.py
- **Location**: All tests should be in the `tests/` directory
- **Naming**: Test files should start with `test_`
- **Run Tests**: Execute with `python -m pytest tests/` or `pytest -q tests`
- **Assertions**: Each test should verify both status codes and response content
- **Edge Cases**: Include tests for error conditions (e.g., empty lists, invalid input)

## Development Workflow

### Setting up Development Environment
```bash
# Install dependencies
pip install -r requirements.txt

# Install package in development mode
pip install -e .
```

### Running Tests Locally
```bash
# Run all tests
python -m pytest tests/ -v

# Run with coverage
coverage run -m pytest tests/
coverage report
```

### Running the Application
```bash
# Using uvicorn directly
uvicorn app.main:app --reload

# Using Docker
docker build -t sample-app .
docker run -p 8000:8000 sample-app
```

## CI/CD Workflows
The repository uses GitHub Actions for continuous integration:

### CI Workflow (`.github/workflows/ci-test.yml`)
1. **Test Job**: Runs on Python 3.11
   - Checks out code
   - Caches pip dependencies
   - Installs dependencies
   - Runs pytest

2. **Build and Smoke Test Job**: 
   - Builds Docker image
   - Runs container
   - Performs smoke tests on endpoints
   - Cleans up containers

**Branches**: Triggered on `main` and `develop` branches for push and pull requests

## Adding New Features
When adding new features:
1. Define API endpoint in `app/main.py`
2. Create Pydantic models for request/response if needed
3. Add comprehensive tests in `tests/test_main.py`
4. Ensure proper error handling with HTTPException
5. Run tests locally before committing
6. Verify Docker build still works

## Error Handling
- Use FastAPI's `HTTPException` for API errors
- Provide meaningful error messages in the `detail` field
- Use appropriate HTTP status codes (400 for bad requests, 404 for not found, etc.)

## Dependencies
- Keep dependencies pinned to specific versions in `requirements.txt`
- Update `setup.cfg` if adding new core dependencies
- Test compatibility after updating any dependency

## Docker Configuration
- Base image should be Python 3.11 or compatible
- Application runs on port 8000
- Health check endpoint is `/health`
- Container should be production-ready with proper signal handling
