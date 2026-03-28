#! ./.venv/bin/python


def main(args):
    return 2.2 * args.wavelength_micrometers * args.f_ratio**2


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Calculate CFZ")
    parser.add_argument(
        "-f",
        "--f-ratio",
        type=float,
        required=True,
    )
    parser.add_argument(
        "-w",
        "--wavelength-micrometers",
        type=float,
        required=False,
        default=0.5,
    )
    args = parser.parse_args()
    print(main(args))
