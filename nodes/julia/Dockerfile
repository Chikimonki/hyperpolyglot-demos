FROM julia:1.9

WORKDIR /app
COPY Project.toml ./
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'

COPY aggregator.jl ./

EXPOSE 8080

CMD ["julia", "--project=.", "aggregator.jl"]
