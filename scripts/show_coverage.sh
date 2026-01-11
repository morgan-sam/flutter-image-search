#!/bin/bash
echo "🧪 Running tests with coverage..."
flutter test --coverage && \
genhtml coverage/lcov.info -o coverage/html && \
xdg-open coverage/html/index.html
