import pytest
from selenium import webdriver

@pytest.mark.e2e
def test_functional():
    browser = webdriver.Firefox()
    browser.get("http://localhost:80")

    assert "Congratulations!" in browser.title
    print("OK")