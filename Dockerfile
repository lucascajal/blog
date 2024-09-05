FROM debian:bookworm-slim

# Install ruby
RUN apt-get update && apt-get install -y ruby-full build-essential

# Install jekyll
RUN gem install jekyll bundler

WORKDIR /app

# Run while installing dependencies every time
CMD ["sh", "-c", "bundle && bundle exec jekyll serve --host 0.0.0.0"]


# Run with dependencies pre-installed in built image
#COPY ./app/Gemfile .
#RUN bundle
#CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
