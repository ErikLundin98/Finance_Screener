import numpy as np

def stddev(X: np.ndarray, sample=True):
    if sample:
        adj = -1
    else:
        adj = 0
    return np.sqrt(1/(X.shape[0]+adj)*np.sum( np.power(X - np.mean(X), 2) ))


