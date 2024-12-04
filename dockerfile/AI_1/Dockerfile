# OpenCV를 포함한 이미지 기반으로 빌드
FROM opencv/opencv:4.5.5-python3 AS builder

# 필요에 따라 추가 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-tools \
    libgstreamer1.0-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 가상환경 생성
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 필요한 Python 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 실행 스테이지
FROM opencv/opencv:4.5.5-python3
WORKDIR /app

# 런타임 의존성 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    gstreamer1.0-plugins-base \
    gstreamer1.0-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 가상환경 복사
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 애플리케이션 파일 복사
COPY . .
RUN mkdir -p storage/output_feedback_frame

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
