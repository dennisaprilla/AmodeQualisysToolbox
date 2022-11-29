function istrue = inrangeof(value1, value2, tolerance)

    if abs(value1 - value2) <= tolerance
        istrue=true;
    else
        istrue=false;
    end

end

