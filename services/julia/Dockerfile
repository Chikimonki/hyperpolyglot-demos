FROM julia:1.9
WORKDIR /app
COPY Project.toml ./
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
COPY libmathcore.so ./
COPY main.jl ./
EXPOSE 8080
CMD ["julia", "--project=.", "main.jl"]
