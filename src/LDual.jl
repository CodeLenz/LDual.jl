#
# Implementação de diferenciação automática - Forward Differences
# Eduardo Lenz 11/05/2017
#
# Para usar:: using FD
#
# x = Dual(1.0, 1.0)
# cos(x)^2 --> vai dar um numero dual, com a segunda parte sendo a derivada, ie 2*cos(x.real)*(-sin(x.real))
#
# Ultima revisão: 18/05/2017 (FUNÇÕES HIPERBÓLICAS)
# Ultima revisão: 16/09/2019 (Julia 1.*)
# Ultima revisão: 15/06/2022 (Arrumando para colocar no git) 
# Ultima revisão: 15/06/2023 (Rotinas do Matheus para ^)
# Últime revisão: 11/03/2024 (Adequação e melhoria de operações)
# 
# using LDual
#
# f(x) = cos(2*x) + 3*x
# x = Dual(1.0,1.0)
#
# Se rodarmos f(x) obteremos  Dual(f(x), df(x))
#
#
module LDual

    # Exports some basic functions from Julia

    export Dual, +, *, -,/,sin,cos, exp, log, sqrt, abs, ^

    # Exports the definitions of one and zero to extend them

    export one, zero

    # Exports a method to convert numbers to dual format

    export convert

    # Exports operations over arrays

    export transpose, dot, Rand, norm

    # Defines the basic dual type

    struct Dual

        real::Float64

        dual::Float64

    end

    ####################################################################
    #                          Some identities                         #
    ####################################################################

    # Multiplicative identity

    import Base:one

    function one(T::Type{Dual})

        return Dual(1.0, 0.0)

    end

    # Aditive identity

    import Base:zero

    function zero(T::Type{Dual})

        return Dual(0.0, 0.0)

    end

    import Base:zero

    function zero(a::Dual)

        return Dual(0.0, 0.0)

    end

    # Converts a number to dual

    import Base:convert

    function convert(::Type{Dual},x::Number)

        return Dual(x, 0.0)

    end

    ####################################################################
    #                         Basic operations                         #
    ####################################################################

    # Let z = f(x), where z and x are dual numbers. The real part of z 
    # is the value of the function f evaluated at the real part of x,
    # while the dual part of z is the derivative of f evaluated at the
    # real part of x but multiplied by the dual part of x

    # Sum of two numbers

    import Base:+

    function +(x::Dual, y::Dual)

        p = x.real + y.real

        d = x.dual + y.dual

        return Dual(p, d)

    end

    # Product of two numbers

    import Base:*

    function *(x::Dual, y::Dual)

        p = x.real*y.real

        d = x.real*y.dual + x.dual*y.real

        return Dual(p, d)

    end

    # Negation of a number

    import Base:-

    function -(x::Dual)

        p = -x.real

        d = -x.dual

        return Dual(p, d)

    end

    # Subtraction of two numbers

    import Base:-

    function -(x::Dual,y::Dual)

        p = x.real - y.real

        d = x.dual - y.dual

        return Dual(p, d)

    end

    # Division between two numbers

    import Base:/

    function /(x::Dual,y::Dual)

        # Catches the case when the real part of the denominator is null

        @assert y.real!=0

        # Calculates the function and its derivative

        function_value = 1.0/y.real

        derivative_value = -1*y.dual/(y.real^2)

        # Returns the dual tuple

        return x*Dual(function_value, derivative_value)

    end

    # Sine function

    import Base:sin

    function sin(x::Dual)

        p = sin(x.real)

        d = cos(x.real)*x.dual

        return Dual(p, d)

    end

    # Cosine

    import Base:cos

    function cos(x::Dual)

        p = cos(x.real)

        d = -sin(x.real)*x.dual

        return Dual(p, d)

    end

    # Tangent

    import Base:tan

    function tan(x::Dual)

        # Avoids division by zero by addressing x.real=pi/2 and -pi/2

        if isodd(abs(div(x.real, (pi/2)))) && mod(x.real, (pi/2))==0

            throw("Tangent is not differentiable at x=", x.real)

        else

            return Dual(tan(x.real), (1/(cos(x.real)^2))*x.dual)

        end

    end

    # Exponential

    import Base:exp

    function exp(x::Dual)

        p = exp(x.real)

        d = p*x.dual

        return Dual(p, d)

    end

    # Hyperbolic tangent

    import Base:tanh

    function tanh(x::Dual)

        e2x = exp(2*x)

        return ((e2x-1.0)/(e2x+1.0))

    end

    # Hyperbolic sine

    import Base:sinh

    function sinh(x::Dual)

        return ((exp(x)-exp(-x))/2)

    end

    # Hyperbolic cosine

    import Base:cosh

    function cosh(x::Dual)

        return ((exp(x)+exp(-x))/2)

    end

    # Natural logarithm

    import Base:log

    function log(x::Dual)

        # Avoids division by zero

        @assert x.real!=0

        p = log(x.real)

        d = x.dual/x.real

        return Dual(p, d)

    end

    # Logarithm of generic base

    import Base:log

    function log(a::Number, x::Dual)

        # Returns the value of the logarithm and the derivative

        return Dual(log(a, x.real), (x.dual/(log(a)*x.real)))

    end

    # Logarithm of base 10

    import Base:log10

    function log10(x::Dual)

        return log(10, x)

    end

    # Square root

    import Base:sqrt

    function sqrt(x::Dual)

        # Avoids division by zero

        @assert x.real!=0

        p = sqrt(x.real)

        d = x.dual/(2*sqrt(x.real))

        return Dual(p, d)

    end

    # Absolute value

    import Base:abs

    function abs(x::Dual)

        # Avoids division by zero

        @assert x.real!=0

        p = abs(x.real)

        d = x.dual*(x.real/abs(x.real))

        return Dual(p, d)

    end

    ####################################################################
    #       Special cases between common numbers and dual numbers      #
    ####################################################################

    # Sum of dual number with non-dual number

    function +(x::Number, y::Dual)

        # Sums them
        
        return Dual(x+y.real, y.dual)

    end

    function +(x::Dual, y::Number)

        # Sums them

        return Dual(x.real+y, x.dual)

    end

    # Subtraction of dual number by non-dual number

    function -(x::Number, y::Dual)

        # Subtracts them

        return Dual(x-y.real, -y.dual)

    end

    function -(x::Dual, y::Number)

        # Subtracts them

        return Dual(x.real-y, x.dual)

    end

    # Multiplication of dual number by non-dual number

    function *(x::Number, y::Dual)

        # Multiplies both

        return Dual(x*y.real, x*y.dual)

    end

    function *(x::Dual, y::Number)

        # Multiplies both

        return Dual(y*x.real, y*x.dual)

    end

    # Division of dual number by non-dual number

    function /(x::Number, y::Dual)

        # Catches the case when the real part of the denominator is null

        @assert y.real!=0

        # Calculates the function and its derivative

        function_value = x/y.real

        derivative_value = -x*y.dual/(y.real^2)

        # Returns the dual tuple

        return Dual(function_value, derivative_value)

    end

    function /(x::Dual, y::Number)

        # Multiplies both

        return Dual(x.real/y, x.dual/y)

    end

    ####################################################################
    #                 Special cases for exponentiation                 #
    ####################################################################

    import Base:^

    # x^y, where x is not dual

    function ^(x::T,y::Dual) where T<:Number

        # Dual(((x)^(y.real)), y.dual*(((pi*im)+log(abs(x)))*(x^y.real)))

        x>=zero(T) || throw(DomainError(x, "Negative values of base fo",
         "r exponentiation are not allowed in the LDual library yet."))

        # Common evaluation

        common_calc = x^(y.real)

        # Caso dz/dy, x constante
        ifelse(x>0,  Dual(common_calc, y.dual*log(x)*common_calc), Dual(
         common_calc, 0.0))

    end 

    # x^y, where x is dual and y is not dual

    function ^(x::Dual,y::T) where T<:Number

        ifelse(y!=zero(T), Dual(((x.real)^(y)), x.dual*(y*(x.real^(y-1))
         )),  Dual(((x.real)^(y)), 0.0) )
    
    end

    # x^y, where both are dual

    function ^(x::Dual,y::Dual)

        # Avoids complex results
        #
        # Dual(((x.real)^(y.real)), (((x.real)^(y.real))*(((log(
        # abs(x.real))+(pi*im))*y.dual)+((y.real/x.real)*x.dual))))

        x.real >= 0 || throw(DomainError(x, "Negative values of base f",
         "or exponentiation are not allowed in the LDual library yet."))  

        # Caso x e y variáveis, ou x^x
    
        common_calc = x.real^y.real

        ifelse(x.real>0, Dual(common_calc, common_calc*((log(x.real)*y.
         dual)+((y.real/x.real)*x.dual))), Dual(common_calc, 0.0) )
    
    end

    ####################################################################
    #                   Vector and matrix definitions                  #
    ####################################################################

    # Transpose operation for vectors

    import LinearAlgebra:transpose

    function transpose(A::Vector{Dual})

        return reshape(A, 1, length(A))

    end

    # Transpose operation for matrices

    import LinearAlgebra:transpose

    function transpose(A::Matrix{Dual})

        return permutedims(A, (2, 1))

    end

    ####################################################################
    #                      Product array by scalar                     #
    ####################################################################

    # Product of a real scalar by a dual array

    function *(x::T2, A::Array{T, N}) where {T<:Dual, T2<:Number, N}

        # Initializes the output 

        V = zeros(Dual, size(A))#zeros(A)

        # Aplica o produto em cada uma das posições

        for i in eachindex(A)

            V[i] = x*A[i]

        end

        return V

    end

    function *(A::Array{T, N}, x::T2) where {T<:Dual, T2<:Number, N}

        # Initializes the output 

        V = zeros(Dual, size(A))#zeros(A)

        # Aplica o produto em cada uma das posições

        for i in eachindex(A)

            V[i] = x*A[i]

        end

        return V

    end

    # Product of a dual scalar by a float array

    function *(x::T2, A::Array{T, N}) where {T<:Number, T2<:Dual, N}

        # Initializes the output 

        V = zeros(Dual, size(A))#zeros(A)

        # Aplica o produto em cada uma das posições

        for i in eachindex(A)

            V[i] = x*A[i]

        end

        return V

    end

    function *(A::Array{T, N}, x::T2) where {T<:Number, T2<:Dual, N}

        # Initializes the output 

        V = zeros(Dual, size(A))

        # Aplica o produto em cada uma das posições

        for i in eachindex(A)

            V[i] = x*A[i]

        end

        return V

    end

    # Product of a dual scalar by a dual array

    function *(x::T, A::Array{T2, N}) where {T<:Dual, T2<:Dual, N}

        # Initializes the output 

        V = zeros(Dual, size(A))#zeros(A)

        # Aplica o produto em cada uma das posições

        for i in eachindex(A)

            V[i] = x*A[i]

        end

        return V

    end

    function *(A::Array{T2, N}, x::T) where {T<:Dual, T2<:Dual, N}

        # Initializes the output 

        V = zeros(Dual, size(A))#zeros(A)

        # Aplica o produto em cada uma das posições

        for i in eachindex(A)

            V[i] = x*A[i]

        end

        return V

    end

    # Dot product

    import LinearAlgebra:dot

    function dot(A::Vector{T},B::Vector{T2}) where {T<:Dual, T2<:Dual}

        v = transpose(A)*B

        # Returns the inner component because the dual vector was trans-
        # posed

        return v[1]

    end

    import LinearAlgebra:dot

    function dot(A::Vector{T},B::Vector{T2}) where {T<:Number, T2<:Dual}

        v = transpose(A)*B

        return v

    end

    import LinearAlgebra:dot

    function dot(A::Vector{T},B::Vector{T2}) where {T<:Dual, T2<:Number}

        v = transpose(A)*B

        # Returns the inner component because the dual vector was trans-
        # posed

        return v[1]

    end

    # Rand function for arrays
    #   rand(T::Type, d1::Integer, dims::Integer...) at random.jl:232
    #   rand(T::Type{FD.dual}, dims...) at /home/lenz/Dropbox/dif_automatica.jl:245
    # VOU USAR Rand
    #import Base.rand

    function Rand(T::Type{Dual}, dims...)

        # Initializes the array

        V = Array{T}(undef,dims)

        # Initializes all the dual values as null

        for i in eachindex(V)

            V[i] = Dual(rand(), 0.0)

        end

        # Returns the array

        return V

    end

    # Norm p=2

    import LinearAlgebra:norm

    function norm(A::Vector{Dual}, p::Real=2)

        # Verifies wheter the asked norm is two

        p==2 || throw("LDual::norm p=2 only is implemented")

        # Converts to vector

        a = vec(A)

        # Evaluates the inner product

        prod = dot(a, a)

        # Returns the square root

        return sqrt(prod)

    end 

    # Defines a function to get the dual components of an array

    function get_dualComponents(A::Array{T,N}) where {T<:Dual, N}

        # Initializes a float array

        A_dual = zeros(Float64, size(A))

        # Iterates through the elements

        for i in eachindex(A_dual)

            A_dual[i] = A[i].dual

        end

        # Returns the dual part

        return A_dual

    end

    # Defines a function to get the real components of an array

    function get_realComponents(A::Array{T,N}) where {T<:Dual, N}

        # Initializes a float array

        A_real = zeros(Float64, size(A))

        # Iterates through the elements

        for i in eachindex(A_real)

            A_real[i] = A[i].real

        end

        # Returns the dual part

        return A_real

    end

end