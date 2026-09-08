import pytest
from django.test import TestCase

@pytest.mark.smoke
class SmokeTest(TestCase):
    def test_smoke(self):
        response = self.client.get("/admin/login/")
        self.assertEqual(response.status_code, 200)
