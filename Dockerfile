FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ruby-full build-essential

RUN gem install jekyll bundler

WORKDIR /app

RUN jekyll new myblog

WORKDIR /app/myblog

RUN bundle install

#CMD ["bash"]
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
