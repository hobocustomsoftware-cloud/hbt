import inspect

from django.test import SimpleTestCase
from django.urls import URLPattern, URLResolver, get_resolver


class ApiVersionHandlerContractTests(SimpleTestCase):
    def test_custom_versioned_handlers_accept_resolver_version_kwarg(self):
        failures = []

        def walk(patterns, versioned=False):
            for pattern in patterns:
                is_versioned = versioned or "version" in str(pattern.pattern)
                if isinstance(pattern, URLResolver):
                    walk(pattern.url_patterns, is_versioned)
                    continue
                if not isinstance(pattern, URLPattern) or not is_versioned:
                    continue
                view_class = getattr(pattern.callback, "view_class", None)
                if view_class is None:
                    continue
                for method_name in getattr(view_class, "http_method_names", ()):
                    handler = view_class.__dict__.get(method_name)
                    if handler is None:
                        continue
                    parameters = inspect.signature(handler).parameters.values()
                    accepts_version = any(
                        parameter.name == "version"
                        or parameter.kind == inspect.Parameter.VAR_KEYWORD
                        for parameter in parameters
                    )
                    if not accepts_version:
                        failures.append(
                            f"{view_class.__module__}.{view_class.__name__}."
                            f"{method_name}"
                        )

        walk(get_resolver().url_patterns)
        self.assertEqual(
            failures,
            [],
            "Versioned API handlers missing version/**kwargs: "
            + ", ".join(failures),
        )
