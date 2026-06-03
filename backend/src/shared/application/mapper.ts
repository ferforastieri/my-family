export interface Mapper<TSource, TDestination> {
  toDto(source: TSource): TDestination;
}

export interface Factory<TInput, TOutput> {
  create(input: TInput): TOutput;
}
